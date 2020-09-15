#!/bin/bash

##################################################################
# GLOBAL
# You shouldn't need to modify these if you don't want to.
# Just make sure you have exported the $ENTITLED_REGISTRY_KEY
#    
# ex. export ENTITLED_REGISTRY_KEY="YOUR ENTITLEMENT KEY"
##################################################################
if [ -z "${ENTITLED_REGISTRY_KEY}" ]; then echo "You must export the ENTITLED_REGISTRY_KEY environment variable prior to running."; exit; fi

ENTITLED_REGISTRY="cp.icr.io"
ENTITLED_REGISTRY_SECRET="ibm-management-pull-secret"
DOCKER_EMAIL="myemail@ibm.com"

###########################
# Parameters for ROKS
# Currently only used for CAM
###########################
ROKS="true"
ROKSREGION="us-south"
ROKSZONE="dal13"

###########################
# CP4MCM Parameters
###########################
# ROKS defaults
# CP4MCM_BLOCK_STORAGECLASS="ibmc-block-gold"
# CP4MCM_FILE_STORAGECLASS="ibmc-file-gold"
# CP4MCM_FILE_GID_STORAGECLASS="ibmc-file-gold-gid"
# 
# OpenShift - OCS Defaults
# CP4MCM_BLOCK_STORAGECLASS="ocs-storagecluster-ceph-rbd"
# CP4MCM_FILE_STORAGECLASS="ocs-storagecluster-cephfs"
# CP4MCM_FILE_GID_STORAGECLASS="ocs-storagecluster-cephfs"

CP4MCM_NAMESPACE="cp4m"
CP4MCM_BLOCK_STORAGECLASS="ibmc-block-gold"
CP4MCM_FILE_STORAGECLASS="ibmc-file-gold"
CP4MCM_FILE_GID_STORAGECLASS="ibmc-file-gold-gid"

CP4MCM_CNMONITORING_REPO="docker.io/cruxdaemon"

# Additional packages can be found here: 
ANSIBLE_SETUP_PACKAGE="ansible-tower-openshift-setup-3.7.2-1.tar.gz"
ANSIBLE_NAMESPACE="ansible-tower"
ANSIBLE_PASSWORD="Passw0rd"

###########################
# CP4I Parameters
###########################
CP4I_NAMESPACE="cp4i"
CP4I_BLOCK_STORAGECLASS="ibmc-block-gold"
CP4I_FILE_STORAGECLASS="ibmc-file-gold"
CP4I_FILE_GID_STORAGECLASS="ibmc-file-gold-gid"


