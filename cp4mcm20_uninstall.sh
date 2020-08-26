


#oc delete installations -n cp4m ibm-management

#oc get operandconfig -n ibm-common-services

#oc delete operandconfig common-service -n ibm-common-services

#oc get operandregistry -n ibm-common-services

#oc delete operandregistry common-service -n ibm-common-services

#oc delete project ibm-common-services


#
# Delete PVCs
#
oc delete pvc -n kube-system data-sre-bastion-postgresql-0
oc delete pvc -n kube-system data-sre-inventory-inventory-redisgraph-0
oc delete pvc -n kube-system etcd-data-multicluster-hub-etcd-0
oc delete pvc -n kube-system hybridgrc-db-pvc-hybridgrc-postgresql-0

oc delete pvc -n ibm-common-services alertmanager-ibm-monitoring-alertmanager-db-alertmanager-ibm-monitoring-alertmanager-0
oc delete pvc -n ibm-common-services mongodbdir-icp-mongodb-0
oc delete pvc -n ibm-common-services mongodbdir-icp-mongodb-1
oc delete pvc -n ibm-common-services mongodbdir-icp-mongodb-2
oc delete pvc -n ibm-common-services prometheus-ibm-monitoring-prometheus-db-prometheus-ibm-monitoring-prometheus-0

oc delete operandconfig common-service -n ibm-common-services
oc delete operandregistry common-service -n ibm-common-services
#
# Delete PVs
#
oc -n kube-system delete secret icp-metering-api-secret 
oc -n kube-public delete configmap ibmcloud-cluster-info
oc -n kube-public delete secret ibmcloud-cluster-ca-cert
oc delete mutatingwebhookconfiguration ibm-common-service-webhook-configuration
oc delete namespace services



oc delete ns management-infrastructure-management
oc delete ns management-infrastructure-monitoring
oc delete ns management-infrastructure-operations
oc delete ns management-infrastructure-security-services
oc delete ns management-infrastructure-grc-policies
oc delete ns management-grc-policies
oc delete ns cp4mcm

oc delete project ibm-common-services

# ./cp4mcm-cleanup-utility.sh --kubeconfigpath ./kubeconfig --mode postUninstallCleanup
# ./cp4mcm-cleanup-utility.sh --kubeconfigpath ~/tmp/kubeconfig --mode postUninstallCleanup