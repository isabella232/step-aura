#!/bin/sh

kubectl="$WERCKER_STEP_ROOT/kubectl"

# for local testing
#kubectl=/usr/local/bin/kubectl

kubecall() {
  kubecall_command="$1"
  kubecall_server="$2"
  kubecall_token="$3"

  display_version

  echo "kubecall called with: "
  echo "         kubecall_command = $kubecall_command"
  echo "         kubecall_server  = $kubecall_server"
  echo "         kubecall_token   = $kubecall_token"
  echo "         WERCKER_STEP_ROOT = $WERCKER_STEP_ROOT"
 

  # echo "Calling ${kubecall_command}"

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
    global_args="$global_args --server=\"$kubecall_server\""
  else
    fail "kubecall: server argument cannot be empty"
  fi

  # token
  if [ -n "$kubecall_token" ]; then
    global_args="$global_args --token=\"$kubecall_token\""
  else
    fail "kubecall: token argument cannot be empty"
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

  WERCKER_AURA_DEBUG=true
  ##info "Running kubctl command"
  echo "INFO: Running kubctl command"
  if [ "$WERCKER_AURA_DEBUG" = "true" ]; then
    ##info "kubectl $global_args $raw_global_args $cmd $args $raw_args"
    echo "INFO: kubectl $global_args $raw_global_args $cmd $args $raw_args"
  fi

  echo
  echo

  echo  eval "$kubectl" "$global_args" "$raw_global_args" "$cmd" "$args" "$raw_args"
  eval "$kubectl" "$global_args" "$raw_global_args" "$cmd" "$args" "$raw_args"


}

display_version() {
  # info "Running kubectl version:"
  echo "INFO: Running kubectl version:"
  "$kubectl" version --client
  echo ""
}

generate_kubeconfig() {
    master="$1"
    token="$2"
    clusterId="$3"

    echo "create /root/.kube"
    mkdir -p /root/.kube

    echo "Write config to file using master: ${master}, clusterId: ${clusterId}"
    echo "
    apiVersion: v1
    clusters:
      - cluster:
          insecure-skip-tls-verify: true
          server: ${master}}
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
    " > /root/.kube/config

}


save_kubeconfig() {

}


# this should not be needed for the published step, but is needed for testing the unpublished step
pull_kubectl_workaround() {
    curl -L https://dl.k8s.io/v1.6.7/kubernetes-client-linux-amd64.tar.gz > kubernetes-client-linux-amd64.tar.gz
    sha256sum kubernetes-client-linux-amd64.tar.gz | grep -q "$KUBERNETES_SHA256"
    tar xvzf kubernetes-client-linux-amd64.tar.gz
    echo "moving kubectl from $CWD to $WERCKER_STEP_ROOT"
    mv kubernetes/client/bin/kubectl "$WERCKER_STEP_ROOT/"
    #kubernetes/client/bin/kubectl version --client
    ${WERCKER_STEP_ROOT}/kubectl version --client

}


# this should not be needed for the published step, but is needed for testing the unpublished step
pull_helm_workaround() {
    helm_version=2.8.2
    helm_archive=helm-v${helm_version}-linux-amd64.tar.gz
    helm_url=https://storage.googleapis.com/kubernetes-helm/${helm_archive}
    curl -L $helm_url
    tar xvzf ${helm_archive}
    echo "moving helm client from $CWD to $WERCKER_STEP_ROOT"

    mv linux-amd64/helm "$WERCKER_STEP_ROOT/"

    ${WERCKER_STEP_ROOT}/helm version 

}



main() {

  server="$WERCKER_STEP_AURA_SERVER"
  token="$WERCKER_STEP_AURA_TOKEN"

  echo "main: WERCKER_STEP_AURA_SERVER - $WERCKER_STEP_AURA_SERVER"
  echo "main: WERCKER_STEP_AURA_TOKEN - $WERCKER_STEP_AURA_TOKEN"

  generate_kubeconfig "$server" "$token" "cluster1"

  echo "Created kubeconfig:"
  cat /root/.kube/config

  # this part should alternatively take a pasted kubeconfig 
  # and make kubecall just use the right context in the new file


  # for unpublished step, pull kubectl from here
  pull_kubectl_workaround
  # for unpublished step, pull helm from here
  pull_helm_workaround

  echo
  echo "Test helm"
  ${WERCKER_STEP_ROOT}/helm version 
  

  echo
  echo "  Contents of $WERCKER_STEP_ROOT"
  ls -R $WERCKER_STEP_ROOT
  echo
 
  # kubecall "get pods --all-namespaces" "$server" "$token"
 
  echo "Create aura namespace"
  # don't fail here if aura namespace exists
  kubecall "create namespace aura" "$server" "$token" || true

  echo "Set up access control"
  kubecall "apply -f rbac.yml" "$server" "$token"



}

main;









