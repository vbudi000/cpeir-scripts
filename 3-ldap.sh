#!/bin/bash

source 0-setup_env.sh

#
# cloudctl login
YOUR_CP4MCM_ROUTE=`oc -n ibm-common-services get route cp-console --template '{{.spec.host}}'`
CP_PASSWORD=`oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d`
cloudctl login -a $YOUR_CP4MCM_ROUTE --skip-ssl-validation -u admin -p $CP_PASSWORD -n default

#
# Create LDAP Resources
#
oc new-project ldap
oc adm policy add-scc-to-user anyuid -z default -n ldap

oc create -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ldap
  labels:
    app: ldap
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ldap
  template:
    metadata:
      labels:
        app: ldap
    spec:
      containers:
        - name: ldap
          image: ibmzavala/openldap:latest
          ports:
            - containerPort: 389
              name: openldap
EOF

oc create -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: ldap
  name: ldap-service
spec:
  ports:
    - port: 389
  selector:
    app: ldap
EOF

echo "Sleeping while LDAP is starting.. (60 seconds)"
sleep 60

#
# Configure CP4MCM LDAP 
#
cloudctl iam ldap-create my_ldap --basedn 'dc=ibm,dc=com' --binddn 'cn=admin,dc=ibm,dc=com' --binddn-password Passw0rd --server ldap://ldap-service.ldap.svc.cluster.local:389 --group-filter '(&(cn=%v)(objectclass=groupOfUniqueNames))' --group-id-map '*:cn' --group-member-id-map 'groupOfUniqueNames:uniqueMember' --user-filter '(&(uid=%v)(objectclass=inetOrgPerson))' --user-id-map '*:uid'
cloudctl iam team-create operations
cloudctl iam group-import --group operations -f
cloudctl iam team-add-groups operations Administrator -g operations


