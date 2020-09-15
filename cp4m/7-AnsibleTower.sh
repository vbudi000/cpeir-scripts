#!/bin/bash

# Source process: https://www.ibm.com/support/knowledgecenter/en/SSFC4F_2.0.0/install/ansible_tower.html

source 0-setup_env.sh

#
# Create ansible-tower project
#
echo "Creating namespace for Ansible Tower."
oc new-project $ANSIBLE_NAMESPACE

#
# Create PVC for the Postgres DB
#
echo "Creating PVC for Ansible Tower."
oc create -f - <<EOF
 apiVersion: v1
 kind: PersistentVolumeClaim
 metadata:
   annotations:
   labels:
   name: postgresql
   namespace: $ANSIBLE_NAMESPACE
 spec:
   accessModes:
   - ReadWriteOnce
   resources:
     requests:
       storage: 10Gi
   storageClassName: $CP4MCM_FILE_GID_STORAGECLASS
EOF

#
# Extract Ansible binaries
#
echo "Extracting Ansible Tower installer."
tar xvf ./cp4m/ansible-tower-openshift-setup-latest.tar.gz -C ./tmp

#
# Change Ansible to use insecure login
#
echo "Patching Ansible Tower installer to use insecure login."
sed -i'.old' "s/{{ openshift_skip_tls_verify | default(false)/{{ openshift_skip_tls_verify | default(true)/g" ./tmp/ansible-tower-openshift-setup-3.7.2-1/roles/kubernetes/tasks/openshift_auth.yml

#
# Get install values
#
echo "Collecting Ansible Tower installation parameters."
KUBE_API_SERVER_HOST=`kubectl get configmap -n kube-public -o jsonpath='{.items[1].data.cluster_kube_apiserver_host}'`
KUBE_API_SERVER_PORT=`kubectl get configmap -n kube-public -o jsonpath='{.items[1].data.cluster_kube_apiserver_port}'`
OPENSHIFT_USER=`oc whoami`
OPENSHIFT_TOKEN=`oc whoami -t`

MY_SECRET=`echo $ANSIBLE_PASSWORD | base64`
PG_USERNAME='admin'
PG_PASSWORD=$ANSIBLE_PASSWORD
RABBITMQ_PASSWORD=$ANSIBLE_PASSWORD
RABBITERLANGAPWD='rabbiterlangapwd'

echo "The following parameters will be passed to the Ansible Tower installer:"
echo "  KUBE_API_SERVER_HOST=$KUBE_API_SERVER_HOST"
echo "  KUBE_API_SERVER_PORT=$KUBE_API_SERVER_PORT"
echo "  OPENSHIFT_USER=$OPENSHIFT_USER"
echo "  OPENSHIFT_TOKEN=$OPENSHIFT_TOKEN"
echo "  MY_SECRET=$MY_SECRET"
echo "  PG_USERNAME=$PG_USERNAME"
echo "  PG_PASSWORD=$PG_PASSWORD"
echo "  RABBITMQ_PASSWORD=$RABBITMQ_PASSWORD"
echo "  RABBITERLANGAPWD=$RABBITERLANGAPWD"

#
# Install Ansible
#
export ANSIBLE_NOCOWS=1
echo "Executing the Ansible Tower installer:"
./tmp/ansible-tower-openshift-setup-3.7.2-1/setup_openshift.sh -e openshift_host=https://$KUBE_API_SERVER_HOST:$KUBE_API_SERVER_PORT -e openshift_project=$ANSIBLE_NAMESPACE -e openshift_user=$OPENSHIFT_USER \
-e openshift_token=$OPENSHIFT_TOKEN -e admin_password=$OPENSHIFT_TOKEN -e secret_key=$MY_SECRET -e pg_username=$PG_USERNAME -e pg_password=$PG_PASSWORD \
-e rabbitmq_password=$RABBITMQ_PASSWORD -e rabbitmq_erlang_cookie=$RABBITERLANGAPWD

#
# Print Login credentials
#
ANSIBLE_ROUTE=`oc get route -n ansible-tower --template '{{.spec.host}}'`

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Ansible Tower installation complete."
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo " You can access User Interface with the URL and credentials below:"
echo " URL=$ANSIBLE_ROUTE"
echo " User=admin"
echo " Password=$ANSIBLE_PASSWORD"
