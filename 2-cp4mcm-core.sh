#!/bin/bash

source 0-setup_env.sh

#if [ -z ${ENTITLED_REGISTRY_KEY} ]; then echo "You must export the ENTITLED_REGISTRY_KEY environment variable prior to running."; exit; fi
#ENTITLED_REGISTRY="cp.icr.io"
#ENTITLED_REGISTRY_SECRET="ibm-management-pull-secret"
#DOCKER_EMAIL="myemail@ibm.com"
#CP_NAMESPACE="cp4m"
#CP4MCM_CORE_STORAGECLASS="ibmc-block-gold"

#CP4MCM_CORE_STORAGECLASS="ocs-storagecluster-ceph-rbd"

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

# CP4MCM CatalogSource
oc create -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: management-installer-index
  namespace: openshift-marketplace
spec:
  displayName: CP4MCM Installer Catalog
  publisher: IBM CP4MCM
  sourceType: grpc
  image: quay.io/cp4mcm/cp4mcm-orchestrator-catalog:2.0.0
  updateStrategy:
    registryPoll:
      interval: 45m
  secrets:
   - $ENTITLED_REGISTRY_SECRET
EOF

#
# Wait for CP4MCM CatalogSource to be created
#
echo "Waiting for CP4MCM CatalogSource (60 seconds)"
sleep 60

#
# Create CP4MCM Subscription
#
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-management-orchestrator
  namespace: openshift-operators
spec:
  channel: 2.0-stable
  installPlanApproval: Automatic
  name: ibm-management-orchestrator
  source: management-installer-index
  sourceNamespace: openshift-marketplace
  startingCSV: ibm-management-orchestrator.v2.0.0
EOF

#
# Wait for CP4MCM Subscription to be created
#
echo "Waiting for CP4MCM Subscription (60 seconds)"
sleep 60

#
# Create the Installation
#
cat << EOF | oc apply -f -
apiVersion: orchestrator.management.ibm.com/v1alpha1
kind: Installation
metadata:
  name: ibm-management
  namespace: cp4m
spec:
  storageClass: $CP4MCM_CORE_STORAGECLASS
  imagePullSecret: $ENTITLED_REGISTRY_SECRET
  license:
    accept: true
  mcmCoreDisabled: false
  pakModules:
    - config:
        - enabled: true
          name: ibm-management-im-install
          spec: {}
        - enabled: true
          name: ibm-management-infra-grc
          spec: {}
        - enabled: true
          name: ibm-management-infra-vm
          spec: {}
        - enabled: true
          name: ibm-management-cam-install
          spec: {}
        - enabled: true
          name: ibm-management-service-library
          spec: {}
      enabled: false
      name: infrastructureManagement
    - config:
        - enabled: true
          name: ibm-management-monitoring
          spec:
            operandRequest: {}
            monitoringDeploy:
              global:
                environmentSize: size0
                persistence:
                  storageClassOption:
                    cassandrabak: none
                    cassandradata: default
                    couchdbdata: default
                    datalayerjobs: default
                    elasticdata: default
                    kafkadata: default
                    zookeeperdata: default
                  storageSize:
                    cassandrabak: 50Gi
                    cassandradata: 50Gi
                    couchdbdata: 5Gi
                    datalayerjobs: 5Gi
                    elasticdata: 5Gi
                    kafkadata: 10Gi
                    zookeeperdata: 1Gi
      enabled: false
      name: monitoring
    - config:
        - enabled: true
          name: ibm-management-notary
          spec: {}
        - enabled: true
          name: ibm-management-image-security-enforcement
          spec: {}
        - enabled: false
          name: ibm-management-mutation-advisor
          spec: {}
        - enabled: false
          name: ibm-management-vulnerability-advisor
          spec:
            controlplane:
              esSecurityEnabled: true
              esServiceName: elasticsearch.ibm-common-services
              esSecretName: logging-elk-certs
              esSecretCA: ca.crt
              esSecretCert: curator.crt
              esSecretKey: curator.key
            annotator:
              esSecurityEnabled: true
              esServiceName: elasticsearch.ibm-common-services
              esSecretName: logging-elk-certs
              esSecretCA: ca.crt
              esSecretCert: curator.crt
              esSecretKey: curator.key
            indexer:
              esSecurityEnabled: true
              esServiceName: elasticsearch.ibm-common-services
              esSecretName: logging-elk-certs
              esSecretCA: ca.crt
              esSecretCert: curator.crt
              esSecretKey: curator.key
      enabled: false
      name: securityServices
    - config:
        - enabled: true
          name: ibm-management-sre-chatops
          spec: {}
      enabled: false
      name: operations
    - config:
        - enabled: true
          name: ibm-management-manage-runtime
          spec: {}
      enabled: false
      name: techPreview
EOF

#
# Wait for CP4MCM Subscription to be created
#
echo "Installation has started. Check status by running 'oc get opreq -A'"
oc get opreq -A

