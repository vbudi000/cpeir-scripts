mcmcore:
	./1-common-services.sh
	./cp4m/2-cp4mcm-core.sh

mcmall:
	./1-common-services.sh
	./cp4m/2-cp4mcm-core.sh
	./cp4m/3-ldap.sh
	./cp4m/4-CAMandIM.sh
	./cp4m/5-CloudFormsandOIDC.sh
	./cp4m/6-MonitoringModule.sh

mcmmonitoring:
	./1-common-services.sh
	./cp4m/2-cp4mcm-core.sh
	./cp4m/3-ldap.sh
	./cp4m/6-MonitoringModule.sh

mcmim:
	./1-common-services.sh
	./cp4m/2-cp4mcm-core.sh
	./cp4m/3-ldap.sh
	./cp4m/4-CAMandIM.sh
	./cp4m/5-CloudFormsandOIDC.sh

mcmenablemonitoring:
	./cp4m/6-MonitoringModule.sh

mcmenableim:
	./cp4m/3-ldap.sh
	./cp4m/4-CAMandIM.sh
	./cp4m/5-CloudFormsandOIDC.sh

cp4icore:
	./1-common-services.sh
	./cp4i/2a-cp4i-core.sh

