#!/bin/bash

source 0-setup_env.sh

#
# Common Services CatalogSource
#
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
sleep 180
echo "Done."