#!/bin/bash

source 0-setup_env.sh

#
# Create Operator Namespace
#
oc new-project common-service

# Common Services CatalogSource
oc create -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: opencloud-operators
  namespace: openshift-marketplace
spec:
  displayName: IBMCS Operators
  publisher: IBM
  sourceType: grpc
  image: docker.io/ibmcom/ibm-common-service-catalog:latest
  updateStrategy:
    registryPoll:
      interval: 45m
EOF

#
# Wait for CatalogSource to be created
#
echo "Waiting for CatalogSource (60 seconds)"
sleep 60

#
# Create CS and ODLM Subscriptions.
# Note: This is only needed because out of the box they ship with the beta channel that doesn't work.
#
## Create Subsciption for common service operator 
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-common-service-operator
  namespace: openshift-operators
spec:
  channel: stable-v1
  installPlanApproval: Automatic
  name: ibm-common-service-operator
  source: opencloud-operators
  sourceNamespace: openshift-marketplace
EOF

#
# Wait for CS Subscription to be created
#
echo "Waiting for CS Subscription (60 seconds)"
sleep 60
echo "Done."