#!/bin/bash

#
# Start of the real brainiac work unlike what the simpleton was doing before boy genius jumped in to save the day
#

if [ -z ${ENTITLED_REGISTRY_KEY} ]; then echo "You must export the ENTITLED_REGISTRY_KEY environment variable prior to running."; exit; fi
ENTITLED_REGISTRY="cp.icr.io"
ENTITLED_REGISTRY_SECRET="ibm-management-pull-secret"
DOCKER_EMAIL="myemail@ibm.com"
CP_NAMESPACE="cp4i"
CP4I_BLOCK_STORAGECLASS="ocs-storagecluster-ceph-rbd"
CP4I_FILE_STORAGECLASS="ocs-storagecluster-cephfs"
CP4I_FILE_GID_STORAGECLASS="ocs-storagecluster-cephfs"

#
# Create Operator Namespace
#
oc new-project $CP_NAMESPACE

#
# Create entitled registry secret
#
oc create secret docker-registry $ENTITLED_REGISTRY_SECRET --docker-username=cp --docker-password=$ENTITLED_REGISTRY_KEY --docker-email=$DOCKER_EMAIL --docker-server=$ENTITLED_REGISTRY -n $CP_NAMESPACE

#
# Import Catalog Source
#

# CP4I CatalogSource
oc create -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: ibm-operator-catalog 
  publisher: IBM Content
  sourceType: grpc
  image: docker.io/ibmcom/ibm-operator-catalog
  updateStrategy:
    registryPoll:
      interval: 45m
EOF

#
# Create CP4I Subscription
#
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-cp-integration
  namespace: openshift-operators
spec:
  channel: v1.0
  installPlanApproval: Automatic
  name: ibm-cp-integration
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
  startingCSV: ibm-cp-integration.v1.0.0
EOF

#
# Wait for CatalogSource to be created
#
echo "Waiting for CatalogSource (32 seconds)"
sleep 132

#
# Create the Installation of the Platform Navigator
#
cat << EOF | oc apply -f -
apiVersion: integration.ibm.com/v1beta1
kind: PlatformNavigator
metadata:
  name: cp4i-navigator
  namespace: $CP_NAMESPACE
spec:
  license:
    accept: true
  mqDashboard: true
  replicas: 3
  version: 2020.2.1
EOF

#
# Create the Installation of the Asset Repo for Sandpit
# For Prod instance remove the replicas 1
#
cat << EOF | oc apply -f -
apiVersion: integration.ibm.com/v1beta1
kind: AssetRepository
spec:
  license:
    accept: true
  replicas: 1
  storage:
    assetDataVolume:
      class: $CP4I_FILE_GID_STORAGECLASS
    couchVolume:
      class: $CP4I_BLOCK_STORAGECLASS
  version: 2020.2.1.1-0
metadata:
  name: asset-repo
  namespace: $CP_NAMESPACE
EOF