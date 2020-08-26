#!/bin/bash

# WC=0
# SLEEP=60
# COUNT=1
# MINUTES=60
# while [ $COUNT -le $MINUTES ]
# do
#   OUT=`oc get po --no-headers=true -A | grep -v 'Running\|Completed' | grep 'kube-system\|ibm-common-services\|management-infrastructure-management\|management-monitoring\|management-operations\|management-security-services'`
#   WC=$(printf "%s\n" "$OUT" | wc -l | tr -d '[:space:]')
#   echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#   echo "Waiting for pods to start.. retry ($COUNT of $MINUTES)(Pods remaining = $WC)"
#   echo ""
#   printf "%s\n" "$OUT"

#   if [ $WC -le 0 ]; 
#   then 
#     COUNT=$MINUTES; 
#   else 
#     sleep $SLEEP
#     COUNT=$(( $COUNT + 1 ));
#   fi
# done

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

# Route
oc get route cp-console -n ibm-common-services

# Password
oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d


