

#YOUR_CP4MCM_ROUTE=`oc -n ibm-common-services get route cp-console --template '{{.spec.host}}'`
#oc patch dc deployment-example -p '{"spec":{"template":{"metadata":{"labels":{"version":"v1"}}}}}'
#YOUR_IM_HTTPD_ROUTE=`echo cp-console.apps.mcmhub.ncolon.xyz |sed s/cp-console/inframgmtinstall/`


#installation.orchestrator.management.ibm.com/ibm-management
oc patch installation.orchestrator.management.ibm.com ibm-management --type=json -n cp4m -p '{"spec":{"pakModules":[{"config":{"name":"infrastructureManagement, "enabled": "true"}}]}}'
cat << EOF | oc patch installation.orchestrator.management.ibm.com ibm-management --type=json -n cp4m -p=
"spec": {
        "pakModules": [
            {
                "config": [
                    {
                        "enabled": true,
                        "name": "ibm-management-im-install",
                        "spec": {}
                    },
                    {
                        "enabled": true,
                        "name": "ibm-management-infra-grc",
                        "spec": {}
                    },
                    {
                        "enabled": true,
                        "name": "ibm-management-infra-vm",
                        "spec": {}
                    },
                    {
                        "enabled": false,
                        "name": "ibm-management-cam-install",
                        "spec": {}
                    },
                    {
                        "enabled": true,
                        "name": "ibm-management-service-library",
                        "spec": {}
                    }
                ],
                "enabled": true,
                "name": "infrastructureManagement"
            }
        ]
        }
EOF