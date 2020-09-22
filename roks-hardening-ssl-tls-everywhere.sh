#!/bin/bash 
# ----------------------------------------------------------------------------------------------------\\
# Description:
#   A basic script to harden the default SSL TLS posture to use valid certificates for a ROKS CP4MCM Env
#
#   Options:
#     [Optional]: CP4MCM ROKS FQDN Hostname (icp-console.something.region.containers.appdomain.com)
#     
#
#   Example:
#     ./01a-cp4mcm-roks-hardening-ssl-tls-everywhere.sh
#
#   Reference: 
#
# ----------------------------------------------------------------------------------------------------\\
set -e

############
# Colors  ##
############
Green='\x1B[0;32m'
Red='\x1B[0;31m'
Yellow='\x1B[0;33m'
Cyan='\x1B[0;36m'
no_color='\x1B[0m' # No Color
beer='\xF0\x9f\x8d\xba'
delivery='\xF0\x9F\x9A\x9A'
beers='\xF0\x9F\x8D\xBB'
coffee='\xE2\x98\x95';
eyes='\xF0\x9F\x91\x80'
cloud='\xE2\x98\x81'
crossbones='\xE2\x98\xA0'
litter='\xF0\x9F\x9A\xAE'
fail='\xE2\x9B\x94'
harpoons='\xE2\x87\x8C'
tools='\xE2\x9A\x92'
present='\xF0\x9F\x8E\x81'
applelogo='\xEF\xA3\xBF'
#############

clear


USAGE="${crossbones}        ${eyes}  Usage: ./${0##*/} ROKS_HOSTNAME\n
\tROKS_HOSTNAME:\tPublic Cloud Hostname for CPK4MCM (e.g. icp-console.something.region.containers.appdomain.cloud \n"

source 0-setup_env.sh

#
# cloudctl login
YOUR_CP4MCM_ROUTE=`oc -n ibm-common-services get route cp-console --template '{{.spec.host}}'`
CP_PASSWORD=`oc -n ibm-common-services get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 -d`


BASE_FQDN=$(echo "${YOUR_CP4MCM_ROUTE}" | cut -d"." -f2-)

# Exit the shell script with a status of 1 using exit 1 command.
echo -e "${tools}   Welcome to the ${Yellow}SSL/TLS Everywhere${no_color} enablement script for ROKS CloudPak for MCM";

if [ "${OSTYPE}" == "rhel" ]; then
  sudo yum install epel-release -y
  sudo yum install jq -y
elif [[ "${OSTYPE}" == "darwin"* ]]; then
  brew install jq >/dev/null;
else
  sudo apt-get -qq install jq -y
fi

echo -e "${eyes}   So, you're looking for urls that carry valid browser certificates?";
echo -e "${eyes}   Well, you've come to the right place. As a nice side-effect, you'll also notice a serious User Interface speed boost";

cloudctl login -a $YOUR_CP4MCM_ROUTE --skip-ssl-validation -u admin -p $CP_PASSWORD -n ibm-common-services

echo -e "${tools}  Extracting the ${Cyan}icp-management-ingress-tls-secret${no_color} ca.crt data ...";
kubectl get secret -n  ibm-common-services icp-management-ingress-tls-secret -o json -o=jsonpath="{.data.ca\.crt}" | base64 --decode | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ca.crt

# CP-CONSOLE
echo -e "${tools}  Backing up the existing icp-console route into ${Cyan}cp-console-route.orig.yaml${no_color} ...";
oc get route cp-console -n ibm-common-services -o yaml > cp-console-route.orig.yaml  #to backup your existing route information.

echo -e "${eyes}  Deleting the cp-console route ...";
oc delete route cp-console -n ibm-common-services

echo -e "${tools} Swapping out the existing cp-console route with a ${Cyan}secured reencrypt route${no_color} ...";
oc create route reencrypt cp-console -n ibm-common-services --hostname cp-console.${BASE_FQDN} --insecure-policy Redirect --service icp-management-ingress --dest-ca-cert ./ca.crt

# ICP-PROXY
# Turning OFF by default.  This causes problems with ICAM urls and needs more investigation to behave correctly.

# echo -e "${tools}  Backing up the existing icp-proxy route into ${Cyan}icp-console-route.orig.yaml${no_color} ...";
# oc get route icp-proxy -n kube-system -o yaml > icp-proxy-route.orig.yaml  #to backup your existing route information.

# echo -e "${eyes}  Deleting the icp-proxy route ...";
# oc delete route icp-proxy -n kube-system

# echo -e "${tools} Swapping out the existing icp-proxy route with a ${Cyan}secured reencrypt route${no_color} ...";
# oc create route reencrypt icp-proxy -n kube-system --hostname icp-proxy.${BASE_FQDN} --insecure-policy None --service nginx-ingress --dest-ca-cert ./ca.crt


# CAM & CloudFroms
detectCAMRoute=$(oc get route -n management-infrastructure-management --no-headers | awk '{print $1}' | grep "cam" | grep "^.*$" -c || true)
if [ "$detectCAMRoute" -eq "0" ]; then
  echo -e "${tools}  No ${Cyan}cam route${no_color} found within the management-infrastructure-management namespace";
else
  echo -e "${tools}  Backing up the existing cam route into ${Cyan}cam-route.orig.yaml${no_color} ...";
  oc get route cam -n management-infrastructure-management -o yaml > cam-route.orig.yaml  #to backup your existing route information.

  echo -e "${eyes}  Deleting the cam route ...";
  oc delete route cam -n management-infrastructure-management

  echo -e "${tools} Swapping out the existing icp-console route with a ${Cyan}secured reencrypt route${no_color} ...";
  oc create route reencrypt cam --namespace management-infrastructure-management --hostname cam.${BASE_FQDN} --insecure-policy Redirect --service cam-proxy --dest-ca-cert ./ca.crt
fi

#ICAM
detectICAM=$(oc get deploy -n management-monitoring | grep cem-users | grep "^.*$" -c || true)
if [ "$detectICAM" -eq "0" ]; then
  echo -e "${tools}  No ${Cyan}Cloud App and Event Management ${no_color} component found within the management-monitoring namespace";
else
  echo -e "${tools}  Creating configmap resource ${Cyan}root-ca-cem-users${no_color} within management-monitoring namespace using the ${Yellow}dst-root-ca-x3${no_color} root certificate.  This certificate is the root cert used by IBM Cloud as a part of their edge TLS termination with Lets Encrypt";
  # Source of dst-root-ca-x3 certificate:  https://www.identrust.com/dst-root-ca-x3
  kubectl create configmap root-ca-cem-users -n management-monitoring --from-file=dst-root-ca-x3.crt
  
  echo -e "${tools}  Patching the ${Cyan}*-ibm-cem-cem-users deployment${no_color} to trust a root certificate defined within a configmap named ${Cyan}root-ca-cem-users${no_color} within the same cem-users deployment namespace ...";
  kubectl patch deploy -n management-monitoring $(oc get deploy -n management-monitoring --no-headers | grep cem-users | awk '{print $1}') --type json -p '[{"op":"add","path":"/spec/template/spec/volumes/-","value":{"configMap":{"defaultMode":420,"name":"root-ca-cem-users"},"name":"masterca"}},{"op":"add","path":"/spec/template/spec/containers/0/volumeMounts/-","value":{"mountPath":"/cem/masterca","name":"masterca"}}]'
fi

# Cleanup
rm -f ca.crt

echo -e "${beers} ${Green}Congrats! You've completed a major upgrade to your Cloud Pak for MultiCloud Management Deployment in terms of both ${Yellow}security and performance${no_color}.  Your environment is now using the edge router Let's Encrypt certificate provided by IBM Cloud. This certifcate is browser trusted and valid.  By using a valid certificate, you lessen the processing delays on every HTTP request.  As a result, UI performance for repeat cached activity should be much quicker."
