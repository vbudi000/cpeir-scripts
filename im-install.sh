
YOUR_CP4MCM_ROUTE=`oc -n ibm-common-services get route cp-console --template '{{.spec.host}}'`
YOUR_IM_HTTPD_ROUTE=`echo cp-console.apps.mcmhub.ncolon.xyz |sed s/cp-console/inframgmtinstall/`
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
# Create links in the UI
#
./automation-navigation-updates.sh -p