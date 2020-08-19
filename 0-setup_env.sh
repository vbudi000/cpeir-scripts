#!/bin/bash

set -e

# GLOBAL
if [ -z "${ENTITLED_REGISTRY_KEY}" ]; then echo "You must export the ENTITLED_REGISTRY_KEY environment variable prior to running."; exit; fi

ENTITLED_REGISTRY="cp.icr.io"
ENTITLED_REGISTRY_SECRET="ibm-management-pull-secret"
DOCKER_EMAIL="myemail@ibm.com"
INSTALL_LDAP="enabled"

ROKS="false"
ROKSREGION="us-south"
ROKSZONE="dal13"

# CP4MCM
CP_NAMESPACE="cp4m"
CP4MCM_CORE_STORAGECLASS="ibmc-block-gold"
CP4MCM_CAM_STORAGECLASS="ibmc-file-gold"

# CP4MCM Modules
INFRASTRUCTURE_MANGEMENT="enabled"
MONITORING="enabled"

# CP4I
CP_NAMESPACE="cp4i"
CP4I_BLOCK_STORAGECLASS="ibmc-block-gold"
CP4I_FILE_STORAGECLASS="ibmc-file-gold"
CP4I_FILE_GID_STORAGECLASS="ibmc-file-gold-gid"


