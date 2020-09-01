#!/bin/bash

# set -e

source 0-setup_env.sh

#
# Create management-infrastructure-management namespace.
#
echo "Create management-infrastructure-management namespace."
oc new-project management-infrastructure-management

#
# Create CAM Service ID API Key
#
# echo "Creating CAM API Key"

# YOUR_CP4MCM_ROUTE=`oc -n ibm-common-services get route cp-console --template '{{.spec.host}}'`
# CP_PASSWORD=`oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d`

# export serviceIDName='service-deploy'
# export serviceApiKeyName='service-deploy-api-key'
# cloudctl login -a $YOUR_CP4MCM_ROUTE --skip-ssl-validation -u admin -p $CP_PASSWORD -n management-infrastructure-management
# cloudctl iam service-id-create ${serviceIDName} -d 'Service ID for service-deploy'
# cloudctl iam service-policy-create ${serviceIDName} -r Administrator,ClusterAdministrator --service-name 'idmgmt'
# cloudctl iam service-policy-create ${serviceIDName} -r Administrator,ClusterAdministrator --service-name 'identity'
# export CAM_API_KEY=`cloudctl iam service-api-key-create ${serviceApiKeyName} ${serviceIDName} -d 'Api key for service-deploy'| tail -1 | awk '{print $3}'`

#
# Updating Installation config with CAM config.
#
if [ $ROKS != "true" ]; 
then 
echo "Adding CAM Config to Installaton (CAM_API_KEY = $CAM_API_KEY)(ROKS = false)";
oc patch installation.orchestrator.management.ibm.com ibm-management -n $CP4MCM_NAMESPACE --type=json -p="[
 {"op": "test",
  "path": "/spec/pakModules/0/name",
  "value": "infrastructureManagement" },
 {"op": "add",
  "path": "/spec/pakModules/0/config/3/spec",
  "value": 
        { "manageservice": {
            "camMongoPV": {"persistence": { "storageClassName": $CP4MCM_FILE_GID_STORAGECLASS}},
            "camTerraformPV": {"persistence": { "storageClassName": $CP4MCM_FILE_GID_STORAGECLASS}},
            "camLogsPV": {"persistence": { "storageClassName": $CP4MCM_FILE_GID_STORAGECLASS}},
            "license": {"accept": true}
            }
        }
  }
]";
else

#
# Updating Installation config with CAM config with ROKS.
#
echo "Adding CAM Config to Installaton (CAM_API_KEY = $CAM_API_KEY)(ROKS = $ROKS)"
oc patch installation.orchestrator.management.ibm.com ibm-management -n $CP4MCM_NAMESPACE --type=json -p="[
 {"op": "test",
  "path": "/spec/pakModules/0/name",
  "value": "infrastructureManagement" },
 {"op": "add",
  "path": "/spec/pakModules/0/config/3/spec",
  "value": 
        { "manageservice": {
            "camMongoPV": {"persistence": { "storageClassName": $CP4MCM_FILE_GID_STORAGECLASS}},
            "camTerraformPV": {"persistence": { "storageClassName": $CP4MCM_FILE_GID_STORAGECLASS}},
            "camLogsPV": {"persistence": { "storageClassName": $CP4MCM_FILE_GID_STORAGECLASS}},
            "global": { "iam": { "deployApiKey": $CAM_API_KEY}},
            "license": {"accept": true},
            "roks": true,
            "roksRegion": "$ROKSREGION",
            "roksZone": "$ROKSZONE"
            }
        }
  }
]"
fi

#
# Enable Infrastructure Management Module
#
echo "Enabling the IM Module in the  Installation"
oc patch installation.orchestrator.management.ibm.com ibm-management -n $CP4MCM_NAMESPACE --type=json -p='[
 {"op": "test",
  "path": "/spec/pakModules/0/name",
  "value": "infrastructureManagement" },
 {"op": "replace",
  "path": "/spec/pakModules/0/enabled",
  "value": true }
]'

#
# Wait for install
#
echo "Installation has started. Check status by running 'oc get opreq -A'"
