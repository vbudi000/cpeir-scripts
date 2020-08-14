#!/bin/bash

#
# Start of the real brainiac work unlike what the simpleton was doing before boy genius jumped in to save the day
#

if [ -z ${ENTITLED_REGISTRY_KEY} ]; then echo "You must export the ENTITLED_REGISTRY_KEY environment variable prior to running."; exit; fi
ENTITLED_REGISTRY="cp.icr.io"
ENTITLED_REGISTRY_SECRET="ibm-entitlement-key"
DOCKER_EMAIL="myemail@ibm.com"
CP_NAMESPACE="cp4i"
CP4I_BLOCK_STORAGECLASS="ibmc-block-gold"
CP4I_FILE_STORAGECLASS="ibmc-file-gold"
CP4I_FILE_GID_STORAGECLASS="ibmc-file-gold-gid"
CP4I_SUFFIX="spectre"
LICENSE="L-AMYG-BQ2E4U"

#
# CP4I Ops Dashboard
#
oc create -f - <<EOF
apiVersion: integration.ibm.com/v1beta1
kind: OperationsDashboard
metadata:
  labels:
    app.kubernetes.io/instance: ibm-integration-operations-dashboard
    app.kubernetes.io/managed-by: ibm-integration-operations-dashboard
    app.kubernetes.io/name: ibm-integration-operations-dashboard
  name: ops-dashb-${CP4I_SUFFIX}
  namespace: $CP_NAMESPACE
spec:
  global:
    images:
      configDb: >-
        cp.icr.io/cp/icp4i/od/icp4i-od-config-db@sha256:ed92ca5a4c4f1afd014148db0f4a75944c2538f78bc18ec382f4c96adc153433
      housekeeping: >-
        cp.icr.io/cp/icp4i/od/icp4i-od-housekeeping@sha256:f923a8e9b61fa76cdfa413f0bd96890123735ff0d32508fe20e371097e8e4cd8
      installAssist: >-
        cp.icr.io/cp/icp4i/od/icp4i-od-install-assist@sha256:900c61098dce803b0be707318c77cb9a40df00c359c936b49c4ff162f2aa0cfb
      legacyUi: >-
        cp.icr.io/cp/icp4i/od/icp4i-od-legacy-ui@sha256:52396f272a6573c51338712fe8b8c0bc72fdf11db37308ef86894fd5b7401625
      oidcConfigurator: >-
        cp.icr.io/cp/icp4i/od/icp4i-od-oidc-configurator@sha256:b5ecb85c10f8716957bc0e3979f36ebc1e1fd800a270eb0065f310f0f9100b6b
      pullPolicy: IfNotPresent
      registrationEndpoint: >-
        cp.icr.io/cp/icp4i/od/icp4i-od-registration-endpoint@sha256:19947e936e00d5eab44e6ece88a6fa4cadbf846df8db1a4748fcf713ea9758e6
      registrationProcessor: >-
        cp.icr.io/cp/icp4i/od/icp4i-od-registration-processor@sha256:c8f5b57d26e411aaa46a26377d2e8e6c95ff862c73e74c935bfa0bb70c02adb6
      reports: >-
        cp.icr.io/cp/icp4i/od/icp4i-od-reports@sha256:e2bda58b1b820fea1b994c279a5fe33de36dd6ffb24eca04cea2f8b4693b968b
      store: >-
        cp.icr.io/cp/icp4i/od/icp4i-od-store@sha256:30492b1c025db622074355f38d713d0609db79000597f9e3fcd92cde142e8048
      storeRetention: >-
        cp.icr.io/cp/icp4i/od/icp4i-od-store-retention@sha256:a82da833b902f9db33ed94fb2b8558d202119a061810d0a791ad6b3bfcab1d5c
      uiManager: >-
        cp.icr.io/cp/icp4i/od/icp4i-od-ui-manager@sha256:c21d756a2ea6a06990bd464cec5674ef1fb9cdf07b1f4a50d1a6abf3784a84df
      uiProxy: >-
        cp.icr.io/cp/icp4i/od/icp4i-od-ui-proxy@sha256:72e00c40d51e6c27a854475985606f9de20c47738a2ab2c987e3bfdbcc2c57a0
    replicas:
      manager: 1
      store: 1
    resources:
      configDb:
        limits:
          cpu: '2'
          memory: 2048Mi
        requests:
          cpu: '0.5'
          memory: 1024Mi
      housekeeping:
        limits:
          cpu: '1'
          memory: 2048Mi
        requests:
          cpu: '0.5'
          memory: 768Mi
      initializationJobs:
        limits:
          cpu: '0.5'
          memory: 512Mi
        requests:
          cpu: '0.25'
          memory: 256Mi
      legacyUi:
        limits:
          cpu: '1'
          memory: 2048Mi
        requests:
          cpu: '0.25'
          memory: 1024Mi
      registrationEndpoint:
        limits:
          cpu: '0.5'
          memory: 1024Mi
        requests:
          cpu: '0.1'
          memory: 256Mi
      registrationProcessor:
        limits:
          cpu: '0.5'
          memory: 1024Mi
        requests:
          cpu: '0.1'
          memory: 384Mi
      reports:
        limits:
          cpu: '8'
          memory: 4096Mi
        requests:
          cpu: '0.5'
          memory: 1024Mi
      store:
        heapSize: 8192M
        limits:
          cpu: '4'
          memory: 10240Mi
        requests:
          cpu: '2'
          memory: 9216Mi
      storeRetention:
        limits:
          cpu: '2'
          memory: 2048Mi
        requests:
          cpu: '0.8'
          memory: 768Mi
      uiManager:
        limits:
          cpu: '4'
          memory: 4096Mi
        requests:
          cpu: '1'
          memory: 1024Mi
      uiProxy:
        limits:
          cpu: '4'
          memory: 1024Mi
        requests:
          cpu: '0.2'
          memory: 512Mi
    storage:
      configDb:
        type: persistent-claim
        volumeClaimTemplate:
          spec:
            resources:
              requests:
                storage: 2Gi
            storageClassName: $CP4I_BLOCK_STORAGECLASS
      store:
        type: persistent-claim
        volumeClaimTemplate:
          spec:
            resources:
              requests:
                storage: 10Gi
            storageClassName: $CP4I_BLOCK_STORAGECLASS
  license:
    accept: true
  version: 2020.2.1-0

EOF

