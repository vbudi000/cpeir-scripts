#!/bin/bash

#
# Start of the real brainiac work unlike what the simpleton was doing before boy genius jumped in to save the day
#

if [ -z ${ENTITLED_REGISTRY_KEY} ]; then echo "You must export the ENTITLED_REGISTRY_KEY environment variable prior to running."; exit; fi
ENTITLED_REGISTRY="cp.icr.io"
ENTITLED_REGISTRY_SECRET="ibm-entitlement-key"
DOCKER_EMAIL="myemail@ibm.com"
CP_NAMESPACE="cp4i"
CP4I_BLOCK_STORAGECLASS="ibmc-block-gold"
CP4I_FILE_STORAGECLASS="ibmc-file-gold"
CP4I_FILE_GID_STORAGECLASS="ibmc-file-gold-gid"
CP4I_SUFFIX="spectre"
LICENSE="L-AMYG-BQ2E4U"


# CP4I App Connect Dashboard Sandbox
oc create -f - <<EOF
apiVersion: appconnect.ibm.com/v1beta1
kind: Dashboard
metadata:
  namespace: $CP_NAMESPACE
  name: appc-dash-${CP4I_SUFFIX}
spec:
  license:
    accept: true
    license: $LICENSE
    use: CloudPakForIntegrationNonProduction
  pod:
    containers:
      content-server:
        resources:
          limits:
            cpu: 250m
            memory: 250Mi
      control-ui:
        resources:
          limits:
            cpu: 250m
            memory: 250Mi
  replicas: 1
  storage:
    class: $CP4I_FILE_GID_STORAGECLASS
    type: persistent-claim
  useCommonServices: true
  version: 11.0.0
EOF

#
# CP4I App Connect Dashboard Production (3 replicas)
#
cat << EOF | oc apply -f -
apiVersion: appconnect.ibm.com/v1beta1
kind: Dashboard
metadata:
  name: ac-dash-${CP4I_SUFFIX}
  namespace: $CP_NAMESPACE
spec:
  license:
    accept: true
    license: $LICENSE
    use: CloudPakForIntegrationProduction
  storage:
    class: $CP4I_FILE_GID_STORAGECLASS
    type: persistent-claim
  useCommonServices: true
  version: 11.0.0
EOF


#
# CP4I App Connect Designer Sandpit 
#
cat << EOF | oc apply -f -
apiVersion: appconnect.ibm.com/v1beta1
kind: DesignerAuthoring
metadata:
  name: appc-des-${CP4I_SUFFIX}
  namespace: $CP_NAMESPACE
spec:
  couchdb:
    replicas: 1
    storage:
      class: $CP4I_BLOCK_STORAGECLASS
      size: 10Gi
      type: persistent-claim
  designerFlowsOperationMode: local
  license:
    accept: true
    license: $LICENSE
    use: CloudPakForIntegrationNonProduction
  replicas: 1
  useCommonServices: true
  version: 11.0.0
  designerMappingAssist:
    enabled: false
EOF

#
# CP4I App Connect Designer Dev (3 replicas & mapping assist)
#
cat << EOF | oc apply -f -
apiVersion: appconnect.ibm.com/v1beta1
kind: DesignerAuthoring
metadata:
  name: appc-des-${CP4I_SUFFIX}
  namespace: $CP_NAMESPACE
spec:
  couchdb:
    storage:
      class: $CP4I_BLOCK_STORAGECLASS
      size: 10Gi
      type: persistent-claim
  designerFlowsOperationMode: local
  license:
    accept: true
    license: $LICENSE
    use: CloudPakForIntegrationNonProduction
  useCommonServices: true
  version: 11.0.0
  designerMappingAssist:
    enabled: true
  replicas: 3
EOF

