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
echo "Creating CAM API Key"

YOUR_CP4MCM_ROUTE=`oc -n ibm-common-services get route cp-console --template '{{.spec.host}}'`
CP_PASSWORD=`oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d`

export serviceIDName='service-deploy'
export serviceApiKeyName='service-deploy-api-key'
cloudctl login -a $YOUR_CP4MCM_ROUTE --skip-ssl-validation -u admin -p $CP_PASSWORD -n management-infrastructure-management
cloudctl iam service-id-create ${serviceIDName} -d 'Service ID for service-deploy'
cloudctl iam service-policy-create ${serviceIDName} -r Administrator,ClusterAdministrator --service-name 'idmgmt'
cloudctl iam service-policy-create ${serviceIDName} -r Administrator,ClusterAdministrator --service-name 'identity'
export CAM_API_KEY=`cloudctl iam service-api-key-create ${serviceApiKeyName} ${serviceIDName} -d 'Api key for service-deploy'| tail -1 | awk '{print $3}'`

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
            "camMongoPV": {"persistence": { "storageClassName": $CP4MCM_CAM_STORAGECLASS}},
            "camTerraformPV": {"persistence": { "storageClassName": $CP4MCM_CAM_STORAGECLASS}},
            "camLogsPV": {"persistence": { "storageClassName": $CP4MCM_CAM_STORAGECLASS}},
            "global": { "iam": { "deployApiKey": $CAM_API_KEY}},
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
            "camMongoPV": {"persistence": { "storageClassName": $CP4MCM_CAM_STORAGECLASS}},
            "camTerraformPV": {"persistence": { "storageClassName": $CP4MCM_CAM_STORAGECLASS}},
            "camLogsPV": {"persistence": { "storageClassName": $CP4MCM_CAM_STORAGECLASS}},
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
#echo "Sleeping for 15 min. while CAM pods start up."
#sleep 900

#
# Patch CAM Pods
#
# change the deployment name . 
#echo -e " Patching the cam-provider-terraform-api deployment resource ..."
#kubectl patch deploy cam-provider-terraform-api -n management-infrastructure-management --type json -p '[{"op":"add","path":"/spec/template/spec/initContainers","value":[{"args":["chown 1111:1111 /home/terraform && chmod 775 /var/camlog"],"command":["/bin/sh","-c"],"image":"alpine:latest","imagePullPolicy":"Always","name":"initcontainer","resources":{},"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"add":["CHOWN","FOWNER","DAC_OVERRIDE"],"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":false,"runAsNonRoot":false,"runAsUser":0,"seLinuxOptions":{"type":"spc_t"}},"terminationMessagePath":"/dev/termination-log","terminationMessagePolicy":"File","volumeMounts":[{"mountPath":"/home/terraform","name":"cam-terraform-pv","subPath":"cam-provider-terraform"},{"mountPath":"/var/camlog","name":"cam-logs-pv"}]}]}]'
#echo -e " Patching the cam-bpd-mariadb deployment resource ..."
#kubectl patch deploy cam-bpd-mariadb -n management-infrastructure-management --type json -p '[{"op":"add","path":"/spec/template/spec/initContainers","value":[{"args":["chown 1000:1000 /var/lib/mysql;"],"command":["/bin/sh","-c"],"image":"alpine:latest","imagePullPolicy":"Always","name":"permissionfix","resources":{},"securityContext":{"capabilities":{"add":["CHOWN"],"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":false,"runAsNonRoot":false,"runAsUser":0,"seLinuxOptions":{"type":"spc_t"}},"terminationMessagePath":"/dev/termination-log","terminationMessagePolicy":"File","volumeMounts":[{"mountPath":"/var/lib/mysql","name":"cam-bpd-appdata-pv","subPath":"mysql"}]}]}]'
