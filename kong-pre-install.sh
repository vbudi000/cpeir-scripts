#/bin/bash

echo "Getting config of ingresscontroller which manages OCP route."
appDomain=`kubectl -n ${INGRESS_OPERATOR_NAMESPACE} get ingresscontrollers default -o json | python -c "import json,sys;obj=json.load(sys.stdin);print obj['status']['domain'];"`
if [ $? -ne 0 ]; then
    echo "Failed to get OCP ingress operator config."
    exit 1
fi

HOST="${NAME}.$appDomain"
KDATA="/opt/kong/data"
export TMPDIR=${KDATA}
cp /opt/kong/config/kong-proxy-route.yaml /opt/kong/data/

echo "Trying to delete the route ${NAME} first."
kubectl -n ${NAMESPACE} delete -f /opt/kong/data/kong-proxy-route.yaml

echo "Creating route ${NAME} to have correct host: ${HOST}."
sed -i 's/host: apis.apps.ibm.com/host: "'$HOST'"/g' /opt/kong/data/kong-proxy-route.yaml
kubectl -n ${NAMESPACE} apply -f /opt/kong/data/kong-proxy-route.yaml
if [ $? -ne 0 ]; then
    echo "Failed to create route ${NAME}."
    exit 1
fi

echo "Successfully created route ${NAME}."
kubectl -n ${NAMESPACE} get route ${NAME}

cp /opt/kong/config/kube-apiserver-tcp-ingress.yaml /opt/kong/data/
echo "Trying to delete the TCPIngress 'kubernetes-api' first."
kubectl delete -f /opt/kong/data/kube-apiserver-tcp-ingress.yaml --ignore-not-found=true

echo "Creating TCPIngress 'kubernetes-api'."
kubectl apply -f /opt/kong/data/kube-apiserver-tcp-ingress.yaml
if [ $? -ne 0 ]; then
    echo "Failed to create TCPIngress 'kubernetes-api'."
    exit 1
fi

echo "Successfully created TCPIngress 'kubernetes-api'."
kubectl -n default get TCPIngress kubernetes-api

echo "Generating cert data."
export RANDFILE=${KDATA}/.rnd
openssl genrsa -out ${KDATA}/kongcert.key 2048
cat >> ${KDATA}/kongcertcsr.conf << EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn
[ dn ]
CN = $(echo $HOST|cut -c -64)
[ req_ext ]
subjectAltName = @alt_names
[ alt_names ]
DNS.1 = $HOST
[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names
EOF

echo "Generating csr"
openssl req -new -key ${KDATA}/kongcert.key -out ${KDATA}/kongcert.csr -config ${KDATA}/kongcertcsr.conf
kubectl get secret loadbalancer-serving-signer -n openshift-kube-apiserver-operator -o jsonpath='{.data.tls\.crt}'|base64 -d > ${KDATA}/lb-signer.crt
kubectl get secret loadbalancer-serving-signer -n openshift-kube-apiserver-operator -o jsonpath='{.data.tls\.key}'|base64 -d > ${KDATA}/lb-signer.key
echo "Creating kongcert"
openssl x509 -req -in ${KDATA}/kongcert.csr -CA ${KDATA}/lb-signer.crt -CAkey ${KDATA}/lb-signer.key \
    -CAcreateserial -out ${KDATA}/kongcert.crt -days 730 \
    -extensions v3_ext -extfile ${KDATA}/kongcertcsr.conf

echo "Creating the Kong TLS cert secret in openshift-config."
kubectl create secret tls kong-tls-cert --cert=${KDATA}/kongcert.crt --key=${KDATA}/kongcert.key -n openshift-config --dry-run -o yaml|kubectl apply -f -
if [ $? -ne 0 ]; then
    echo "Failed to create cert secret for Kong in openshift-config namespace."
    exit 1
fi

echo "Patch the apiserver to add named certificate."
kubectl patch apiserver cluster --type=merge -p '{"spec":{"servingCerts":{"namedCertificates":[{"names":["'$HOST'"],"servingCertificate":{"name":"kong-tls-cert"}}]}}}'
if [ $? -ne 0 ]; then
    echo "Failed to patch the apiserver to add named certificate."
    exit 1
fi