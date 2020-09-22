FROM ubuntu:18.04 as osinstall

WORKDIR /usr/src/CP4MCM_20
COPY . ./

# Install prerequisities for Ansible
RUN apt-get update
RUN apt-get -y install build-essential
RUN apt-get -y install python3 python3-nacl python3-pip libffi-dev

FROM osinstall as ansibleinstall
# Install ansible
RUN pip3 install ansible

# update 
RUN apt-get update
# install curl and wget
RUN apt install curl -y
RUN apt-get install wget

RUN wget https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
RUN tar -xzf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
RUN mv ./openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/oc /usr/local/bin
RUN mv ./openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/kubectl /usr/local/bin

FROM ansibleinstall as scriptinstall
# permissions for the bash scripts
RUN find /usr/src/CP4MCM_20 -type f -iname "*.sh" -exec chmod +x {} \;

CMD ./0-setup_env.sh && make mcmall
