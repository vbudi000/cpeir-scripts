#!/bin/bash

# Sleep until all pods are running.
for ((time=0;time<60;time++)); do
  OUT=`oc get po --no-headers=true -A | grep -v 'Running\|Completed' | grep 'kube-system\|ibm-common-services\|management-infrastructure-management\|management-monitoring\|management-operations\|management-security-services'`
  WC=$(printf "%s\n" "$OUT" | wc -l | tr -d '[:space:]')
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo "Waiting for pods to start.. retry ($time of 60)(Pods remaining = $WC)"
  echo ""
  printf "%s\n" "$OUT"
  
  if [ $WC -le 0 ]; then
    break
  fi
  sleep 60
done

# Get the CP Route
YOUR_CP4MCM_ROUTE=`oc -n ibm-common-services get route cp-console --template '{{.spec.host}}'`

# Get the CP Password
CP_PASSWORD=`oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d`

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Installation complete."
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo " You can access your cluster with the URL and credentials below:"
echo " URL=$YOUR_CP4MCM_ROUTE"
echo " User=admin"
echo " Password=$CP_PASSWORD"



