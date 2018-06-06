#!/bin/sh

# This step will install the Aura microservice platform as part of a Wercker pipeline
#
# Parameters:
#   KUBERNETES_MASTER - specifies the full address of the master node of the target kubernetes cluster
#                       including protocol and port.  ie https://<url>:6443
#   KUBERNETES_TOKEN  - the authentication token for a user with permission to install into the cluster
#                       this can be taken from the kubectl config file
#   PULL_DEPENDENCIES - "true" if the step is being run from an unpublished source
#                       this will cause the step to download kubectl and helm as part of the pipeline
#                       the published step will already include these in its image
#   INSTALL_TYPE      - "install" - the default, will install the Aura platform
#                       "uninstall" - will uninstall the Aura platform
#

kubectl="$WERCKER_STEP_ROOT/kubectl"

# for local testing
#kubectl=/usr/local/bin/kubectl

kubecall() {
  kubecall_command="$1"
  kubecall_server="$2"
  kubecall_token="$3"

  echo "INFO: Running kubectl version:"
  "$kubectl" version --client

  echo "kubecall called with: "
  echo "         kubecall_command = $kubecall_command"
  echo "         kubecall_server  = $kubecall_server"
  echo "         WERCKER_STEP_ROOT = $WERCKER_STEP_ROOT"
 

  if [ -z "$kubecall_command" ]; then
    fail "kubecall: command argument cannot be empty"
    # local echo "FAIL: kubecall: command argument cannot be empty"
  fi

  cmd="$kubecall_command"

  # Global args
  #global_args
  global_args=
  raw_global_args="$WERCKER_AURA_RAW_GLOBAL_ARGS"


  # server
  if [ -n "$kubecall_server" ]; then
    #global_args="$global_args --server=\"$kubecall_server\""
    echo "skipping server param"
  else
    fail "kubecall: server argument cannot be empty"
  fi

  # token
  if [ -n "$kubecall_token" ]; then
    # global_args="$global_args --token=\"$kubecall_token\""
    echo "skipping token param"
  else
    fail "kubecall: token argument cannot be empty"
  fi

  # client-certificate
  if [ -n "$WERCKER_KUBECTL_CLIENT_CERTIFICATE" ]; then
    global_args="$global_args --client-certificate=\"$WERCKER_KUBECTL_CLIENT_CERTIFICATE\""
  fi
    # client-key
  if [ -n "$WERCKER_KUBECTL_CLIENT_KEY" ]; then
    global_args="$global_args --client-key=\"$WERCKER_KUBECTL_CLIENT_KEY\""
  fi


  # insecure-skip-tls-verify
  #if [ -n "$WERCKER_KUBECTL_INSECURE_SKIP_TLS_VERIFY" ]; then
  #  global_args="$global_args --insecure-skip-tls-verify=\"$WERCKER_KUBECTL_INSECURE_SKIP_TLS_VERIFY\""
  #fi
  global_args="$global_args --insecure-skip-tls-verify=\"true\""

  # timeout
  #if [ -n "$WERCKER_KUBECTL_TIMEOUT" ]; then
  #  args="$args --timeout=\"$WERCKER_KUBECTL_TIMEOUT\""
  #fi

  echo  eval "$kubectl" "$global_args" "$raw_global_args" "$cmd" "$args" "$raw_args"
  eval "$kubectl" "$global_args" "$raw_global_args" "$cmd" "$args" "$raw_args"

}


# This is used by helm calls
generate_kubeconfig() {
    master="$1"
    token="$2"
    clusterId="$3"
    kubeconfig_path="$4"

    # echo "create /root/.kube"
    # mkdir -p /root/.kube

    echo "Write config to file using master: ${master}, clusterId: ${clusterId}"
    echo "
    apiVersion: v1
    clusters:
      - cluster:
          insecure-skip-tls-verify: true
          server: ${master}
        name: cluster-${clusterId}
    contexts:
      - context:
          cluster: cluster-${clusterId}
          user: user-${clusterId}
        name: context-${clusterId}
    current-context: context-${clusterId}
    kind: \"\"
    users:
      - name: user-${clusterId}
        user:
              token: ${token}
    " > "$kubeconfig_path"

}


# this should not be needed for the published step, but is needed for testing the unpublished step
pull_kubectl() {
    curl -L https://dl.k8s.io/v1.6.7/kubernetes-client-linux-amd64.tar.gz > kubernetes-client-linux-amd64.tar.gz
    sha256sum kubernetes-client-linux-amd64.tar.gz | grep -q "$KUBERNETES_SHA256"
    tar xvzf kubernetes-client-linux-amd64.tar.gz
    echo "moving kubectl from $PWD to $WERCKER_STEP_ROOT"
    mv kubernetes/client/bin/kubectl "$WERCKER_STEP_ROOT/"
    #kubernetes/client/bin/kubectl version --client
    ${WERCKER_STEP_ROOT}/kubectl version --client

}


# this should not be needed for the published step, but is needed for testing the unpublished step
pull_helm() {
    helm_version=2.8.2
    helm_archive=helm-v${helm_version}-linux-amd64.tar.gz
    helm_url=https://storage.googleapis.com/kubernetes-helm/${helm_archive}
    echo "About to pull helm"
    curl -L $helm_url > $helm_archive
    echo "About to extract helm"
    tar xvzf ${helm_archive}
    echo "just did -  tar xzf ${helm_archive}"
    echo "showing listing of linux-amd64"
    ls linux-amd64
    echo "moving helm client from $PWD to $WERCKER_STEP_ROOT"
    mv linux-amd64/helm "$WERCKER_STEP_ROOT/"

    echo "Test Helm"
    ${WERCKER_STEP_ROOT}/helm version --client

}


# main method starts here 
main() {
  server="$WERCKER_STEP_AURA_SERVER"
  token="$WERCKER_STEP_AURA_TOKEN"
  kubeconfig="$KUBECONFIG_TEXT"

  # echo "INFO: WERCKER_STEP_AURA_SERVER - $WERCKER_STEP_AURA_SERVER"
  # echo "INFO: WERCKER_STEP_AURA_TOKEN - $WERCKER_STEP_AURA_TOKEN"
  echo "INFO: PULL_DEPENDENCIES - $PULL_DEPENDENCIES"
  echo "INFO: INSTALL_TYPE - $INSTALL_TYPE"
  echo "INFO: KUBECONFIG_TEXT - $KUBECONFIG_TEXT"

  # this part should alternatively take a pasted kubeconfig 
  # and make kubecall just use the right context in the new file

  ROOT_KUBECONFIG_PATH="/root/.kube/config"
  mkdir "/root/.kube/"

  if [ ! "${KUBECONFIG_TEXT}" = "" ] ; then
     echo "Using supplied kubeconfig"
     # echo "${KUBECONFIG_TEXT}" >> ${ROOT_KUBECONFIG_PATH}

     # wercker maps newlines to "\n" all on a single line
     echo "${KUBECONFIG_TEXT}" | sed 's/\\n/\
/g' >> ${ROOT_KUBECONFIG_PATH}


     # for testing
     token="token"
     server="server"
  else
     echo "Generating kubeconfig"
     generate_kubeconfig "$server" "$token" "cluster1" "${ROOT_KUBECONFIG_PATH}"
  fi

  echo "Using kubeconfig:"
  cat "${ROOT_KUBECONFIG_PATH}"


  # for running an unpublished step, kubectl and helm must be pulled during run
  # for a published step, they will be installed as part of the step's image
  if [ "$PULL_DEPENDENCIES" == "true" ] ; then
      echo "INFO: pulling kubectl"
      pull_kubectl
      echo "INFO: pulling helm"
      pull_helm
  fi


  echo "Set up access control"
  kubecall "apply -f ${WERCKER_STEP_ROOT}/rbac.yml" "$server" "$token"

  # for testing
  exit 0

  # lowerCase=$(echo "$INSTALL_TYPE" | tr '[:upper:]' '[:lower:]' )

  if [ "$INSTALL_TYPE" = "uninstall" ] ; then
      echo "Uninstalling Aura"

      echo "Delete previous install job"
      kubecall "delete job -n aura uninstall-aura-full --ignore-not-found" "$server" "$token"

      echo "Apply the uninstaller job"
      kubecall "apply -f ${WERCKER_STEP_ROOT}/aura-uninstaller-job-full.yml" "$server" "$token"
  else
      echo "Installing Aura" 

      echo "Delete previous install job"
      #kubecall "delete job -n aura install-aura --ignore-not-found" "$server" "$token"
      kubecall "delete job -n aura install-aura-full --ignore-not-found" "$server" "$token"
      #kubecall "delete job -n aura install-events-broker --ignore-not-found" "$server" "$token"

      echo "Create aura namespace"
      # don't fail here if aura namespace exists
      kubecall "create namespace aura" "$server" "$token" || true

      echo "Set up Istio injection"
      kubecall "label namespace default istio-injection=enabled --overwrite=true" "$server" "$token" 

      # this should come from public public storage
      echo "Apply the installer job"
      kubecall "apply -f ${WERCKER_STEP_ROOT}/aura-installer-job-full.yml" "$server" "$token"
  fi

}

main;


