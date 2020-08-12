
YOUR_CP4MCM_ROUTE=`oc -n ibm-common-services get route cp-console --template '{{.spec.host}}'`
YOUR_IM_HTTPD_ROUTE=`echo $YOUR_CP4MCM_ROUTE |sed s/cp-console/inframgmtinstall/`
SECRET="ibm-management-pull-secret"


#
# Create IMInstall
#
oc create -f - <<EOF
apiVersion: infra.management.ibm.com/v1alpha1
kind: IMInstall
metadata:
  labels:
    app.kubernetes.io/instance: ibm-infra-management-install-operator
    app.kubernetes.io/managed-by: ibm-infra-management-install-operator
    app.kubernetes.io/name: ibm-infra-management-install-operator
  name: im-iminstall
  namespace: management-infrastructure-management
spec:
  applicationDomain: $YOUR_IM_HTTPD_ROUTE
  imagePullSecret: $SECRET
  httpdAuthenticationType: openid-connect
  httpdAuthConfig: imconnectionsecret
  enableSSO: true
  initialAdminGroupName: operations
  license:
    accept: true
  orchestratorInitialDelay: '2400'
EOF

#
# Create Connection
#
oc create -f - <<EOF
 apiVersion: infra.management.ibm.com/v1alpha1
 kind: Connection
 metadata:
   annotations:
     BypassAuth: "true"
   labels:
    controller-tools.k8s.io: "1.0"
   name: imconnection
   namespace: "management-infrastructure-management"
 spec:
   cfHost: web-service.management-infrastructure-management.svc.cluster.local:3000
EOF

#
# Create CAM Service ID API Key
#
YOUR_CP4MCM_ROUTE=`oc -n ibm-common-services get route cp-console --template '{{.spec.host}}'`
CP_PASSWORD=`oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d`

export serviceIDName='service-deploy'
export serviceApiKeyName='service-deploy-api-key'
cloudctl login -a $YOUR_CP4MCM_ROUTE --skip-ssl-validation -u admin -p $CP_PASSWORD -n management-infrastructure-management
cloudctl iam service-id-create ${serviceIDName} -d 'Service ID for service-deploy'
cloudctl iam service-policy-create ${serviceIDName} -r Administrator,ClusterAdministrator --service-name 'idmgmt'
cloudctl iam service-policy-create ${serviceIDName} -r Administrator,ClusterAdministrator --service-name 'identity'
CAM_API_KEY=`cloudctl iam service-api-key-create ${serviceApiKeyName} ${serviceIDName} -d 'Api key for service-deploy'| tail -1 | awk '{print $3}'`

#
# Enable Infrastructure Management Module
#
oc patch installation.orchestrator.management.ibm.com ibm-management -n cp4m --type=json -p='[
 {"op": "test",
  "path": "/spec/pakModules/0/name",
  "value": "infrastructureManagement" },
 {"op": "replace",
  "path": "/spec/pakModules/0/enabled",
  "value": true }
]'

#
# Create links in the UI
#
./automation-navigation-updates.sh -p

