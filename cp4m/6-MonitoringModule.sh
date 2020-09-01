#!/bin/bash

source 0-setup_env.sh

YOUR_CP4MCM_ROUTE=`oc -n ibm-common-services get route cp-console --template '{{.spec.host}}'`
CP_PASSWORD=`oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d`

#
# Adding Monitoring Storage Config.
#
echo "Adding Monitoring Storage Config to Installaton"
oc patch installation.orchestrator.management.ibm.com ibm-management -n $CP4MCM_NAMESPACE --type=json -p="[
 {"op": "test",
  "path": "/spec/pakModules/1/name",
  "value": "monitoring" },
 {"op": "replace",
  "path": "/spec/pakModules/1/config/0/spec",
  "value": 
    {
      "monitoringDeploy": {
        "cnmonitoringimagesource": {
          "deployMCMResources": true
        },
        "global": {
          "environmentSize": size0,
          "persistence": {
            "storageClassOption": {
              "cassandrabak": none,
              "cassandradata": $CP4MCM_BLOCK_STORAGECLASS,
              "couchdbdata": $CP4MCM_BLOCK_STORAGECLASS,
              "datalayerjobs": $CP4MCM_BLOCK_STORAGECLASS,
              "elasticdata": $CP4MCM_BLOCK_STORAGECLASS,
              "kafkadata": $CP4MCM_BLOCK_STORAGECLASS,
              "zookeeperdata": $CP4MCM_BLOCK_STORAGECLASS
            },
            "storageSize": {
              "cassandrabak": 50Gi,
              "cassandradata": 50Gi,
              "couchdbdata": 5Gi,
              "datalayerjobs": 5Gi,
              "elasticdata": 5Gi,
              "kafkadata": 10Gi,
              "zookeeperdata": 1Gi
            }
          }
        }
      }
    }
  }
]"

#
# Updating Installation config with CAM config.
#
echo "Enabling Monitoring Module"
oc patch installation.orchestrator.management.ibm.com ibm-management -n $CP4MCM_NAMESPACE --type=json -p='[
 {"op": "test",
  "path": "/spec/pakModules/1/name",
  "value": "monitoring" },
 {"op": "replace",
  "path": "/spec/pakModules/1/enabled",
  "value": true }
]'

echo "Sleeping until install starts."
sleep 900

#
# Onboarding users.
#
cloudctl login -a $YOUR_CP4MCM_ROUTE --skip-ssl-validation -u admin -p $CP_PASSWORD -n default

cloudctl iam user-import --user bob -f
cloudctl iam user-import --user tom -f
cloudctl iam user-onboard id-mycluster-account -r PRIMARY_OWNER -u bob
cloudctl iam user-onboard id-mycluster-account -r MEMBER -u tom

#
# Patching the CNMonitoring deployable secret.
#
echo "Docker config for SECRET=$ENTITLED_REGISTRY_SECRET in NAMESPACE=$CP4MCM_NAMESPACE"
ENTITLED_REGISTRY_DOCKERCONFIG=`oc get secret $ENTITLED_REGISTRY_SECRET -n $CP4MCM_NAMESPACE -o jsonpath='{.data.\.dockerconfigjson}'`
echo "ENTITLED_REGISTRY_DOCKERCONFIG=$ENTITLED_REGISTRY_DOCKERCONFIG"
oc patch deployable.app.ibm.com/cnmon-pullsecret-deployable -p `echo {\"spec\":{\"template\":{\"data\":{\".dockerconfigjson\":\"$ENTITLED_REGISTRY_DOCKERCONFIG\"}}}}` --type merge -n management-monitoring

#
# Check CN Monitoring Deployables
#
oc get deployable.app.ibm.com -n management-monitoring
oc get channel.app.ibm.com -n management-monitoring cnmon-chl
oc get subscription.app.ibm.com -n management-monitoring cnmon-sub
oc get placementrule.app.ibm.com -n management-monitoring cnmon-pr
oc get monitoringdeploy $(oc get monitoringdeploy -n management-monitoring --no-headers | awk '{print $1}') -n management-monitoring -o yaml | grep 'helmRepo\|dockerReg'

