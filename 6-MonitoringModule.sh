#!/bin/bash

source 0-setup_env.sh

#
# Updating Installation config with CAM config.
#
echo "Enabling Monitoring Mondule"
oc patch installation.orchestrator.management.ibm.com ibm-management -n cp4m --type=json -p='[
 {"op": "test",
  "path": "/spec/pakModules/1/name",
  "value": "monitoring" },
 {"op": "replace",
  "path": "/spec/pakModules/1/enabled",
  "value": true }
]'


YOUR_CP4MCM_ROUTE=`oc -n ibm-common-services get route cp-console --template '{{.spec.host}}'`
CP_PASSWORD=`oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d`
cloudctl login -a $YOUR_CP4MCM_ROUTE --skip-ssl-validation -u admin -p $CP_PASSWORD -n default

cloudctl iam user-import --user bob -f
cloudctl iam user-import --user tom -f
cloudctl iam user-onboard id-mycluster-account -r PRIMARY_OWNER -u bob
cloudctl iam user-onboard id-mycluster-account -r MEMBER -u tom