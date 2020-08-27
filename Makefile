mcmcore:
	./1-common-services.sh
	./cp4m/2-cp4mcm-core.sh
	./status.sh

mcmmonitoring:
	./1-common-services.sh
	./cp4m/2-cp4mcm-core.sh
	./cp4m/3-ldap.sh
	./cp4m/6-MonitoringModule.sh
	./status.sh

mcmim:
	./1-common-services.sh
	./cp4m/2-cp4mcm-core.sh
	./cp4m/3-ldap.sh
	./cp4m/4-CAMandIM.sh
	./cp4m/5-CloudFormsandOIDC.sh
	./status.sh

cp4icore:
	./1-common-services.sh
	./cp4i/2a-cp4i-core.sh

