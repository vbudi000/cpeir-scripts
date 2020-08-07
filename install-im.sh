

YOUR_CP4MCM_ROUTE=`oc -n ibm-common-services get route cp-console --template '{{.spec.host}}'`
oc patch dc deployment-example -p '{"spec":{"template":{"metadata":{"labels":{"version":"v1"}}}}}'
YOUR_IM_HTTPD_ROUTE=`echo cp-console.apps.mcmhub.ncolon.xyz |sed s/cp-console/inframgmtinstall/`
