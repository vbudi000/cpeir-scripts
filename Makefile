mcmcore:
	./1-common-services.sh
	./2-cp4mcm-core.sh
	./status.sh

mcmcoreandmonitoring:
	./1-common-services.sh
	./2-cp4mcm-core.sh
	./6-MonitoringModule.sh
	./status.sh

test:
	echo "All"


cp4icore:

