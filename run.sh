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
  echo
  echo
  echo "  Contents of $WERCKER_STEP_ROOT"
  ls -R $WERCKER_STEP_ROOT
  echo
  echo

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

main() {

  server="https://cqtomjsha4t.us-phoenix-1.clusters.oci.oraclecloud.com:6443"
  token="eyJoZWFkZXIiOnsiQXV0aG9yaXphdGlvbiI6WyJTaWduYXR1cmUgdmVyc2lvbj1cIjFcIixrZXlJZD1cIm9jaWR2MTp0ZW5hbmN5Om9jMTpwaHg6MTQ2MTI3NDcyNjYzMzphYWFhYWFhYW14NWhpbHpoZHd2ZHM1d2ZzbjJha3V5dHk0L29jaWQxLnVzZXIub2MxLi5hYWFhYWFhYWRvdHp0dXV2dHd5NG1uNTcydDZiYnZjYW9iNWpwc2NiN3ZvNGpwdHFnZHN2a3UzdnFjanEvNGM6MTU6OTY6OWI6NjA6Nzg6MTA6MjM6Mzk6ZDE6M2Q6OGU6ODM6MmU6YzE6NjhcIixhbGdvcml0aG09XCJyc2Etc2hhMjU2XCIsaGVhZGVycz1cIihyZXF1ZXN0LXRhcmdldCkgZGF0ZSBob3N0IHgtY29udGVudC1zaGEyNTYgY29udGVudC10eXBlIGNvbnRlbnQtbGVuZ3RoXCIsc2lnbmF0dXJlPVwiRll3TTVkdjFYV2VMVC9rci92T1k5M3ltT3Nsc1JJTG9xTFN4bHovNDFtc3FSRlE0WGVYclBKQktWb2pBU0tiMTBla3VXU244aktJOVdyempaMkg4MjVJYUhvakdaL2lPcjdQVjZTd3J3N3B2RVYzbU1Wb2xNNmkvMEZCV3Q4Zit2dHlHTHFwcXhOWm5Cbm9tYUVTVE1zbDZXTUdZVjVtbUhZTmdFcy93MmJxNndubVR1anVIa0VnbHFOYzdqVmZKbGlPVmd1YTA2Ung4Wks1L2F3cDNHK3drbDFldTZ5RUt5QUh4RC9rNHYyblh5bWFHaVhFREhCOEN0WUMrM0RiSlFZRlA5d3NhNmFSUFRaWk9CQkFMZ2dCeFZnbmNyNU9MVzk2RWQvU3RIYlEyQnl4dDJEcDhDa3RFMzZ6Y2hDUWdQYWFZS1ZqSkh5VFpIMUVUZ2E3VFNnPT1cIiJdLCJDb250ZW50LUxlbmd0aCI6WyIwIl0sIkNvbnRlbnQtVHlwZSI6WyJhcHBsaWNhdGlvbi9qc29uIl0sIkRhdGUiOlsiVHVlLCAwOCBNYXkgMjAxOCAwODozMDo0MyBHTVQiXSwiWC1Db250ZW50LVNoYTI1NiI6WyI0N0RFUXBqOEhCU2ErL1RJbVcrNUpDZXVRZVJrbTVOTXBKV1pHM2hTdUZVPSJdfSwiYm9keSI6eyJ0b2tlblZlcnNpb24iOiIxLjAuMCIsImV4cGlyYXRpb24iOjI1OTIwMDAwMDAwMDAwMDB9LCJob3N0IjoiY29udGFpbmVyZW5naW5lLnVzLXBob2VuaXgtMS5vcmFjbGVjbG91ZC5jb20iLCJyZXF1ZXN0X3VyaSI6Ii9hcGkvMjAxODAyMjIvY2x1c3RlcnMvb2NpZDEuY2x1c3Rlci5vYzEucGh4LmFhYWFhYWFhYWV6d2ttZGZnNDJ0aW56d21tNHRveXJ3aGF5ZHNtdGJnaTN0c3psYmhjcXRvbWpzaGE0dC9rdWJlY29uZmlnL2NvbnRlbnQifQ=="

  server="$WERCKER_STEP_AURA_SERVER"
  token="$WERCKER_STEP_AURA_TOKEN"

  echo "main: WERCKER_STEP_AURA_SERVER - $WERCKER_STEP_AURA_SERVER"
  echo "main: WERCKER_STEP_AURA_TOKEN - $WERCKER_STEP_AURA_TOKEN"


  kubecall "get pods --all-namespaces" "$server" "$token"
  kubecall "create namespace test1" "$server" "$token"

}

main;









