#!/bin/bash

WC=0
SLEEP=60
COUNT=1
MINUTES=60
while [ $COUNT -le $MINUTES ]
do
  OUT=`oc get po --no-headers=true -A | grep -v 'Running\|Completed' | grep 'kube-system\|ibm-common-services\|management-infrastructure-management'`
  WC=$(printf "%s\n" "$OUT" | wc -l | tr -d '[:space:]')
  echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  echo "Waiting for pods to start.. retry ($COUNT of $MINUTES)(Pods remaining = $WC)"
  echo ""
  printf "%s\n" "$OUT"

  if [ $WC -le 0 ]; 
  then 
    COUNT=$MINUTES; 
  else 
    sleep $SLEEP
    COUNT=$(( $COUNT + 1 ));
  fi
done
