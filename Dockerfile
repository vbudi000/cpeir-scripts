# stage: 1 - build
# FROM us.icr.io/xcomp-gold/node:11.11-alpine as node-build
FROM ubuntu:18.04

WORKDIR /usr/src/CP4MCM_20
COPY . ./

# Install prerequisities for Ansible
RUN apt-get update
RUN apt-get -y install python3 python3-nacl python3-pip libffi-dev

# Install ansible
RUN pip3 install ansible

# update 
RUN apt-get update
# install curl 
RUN apt install nodejs -y
# and install node 
RUN apt-get install npm -y
# confirm that it was successful 
RUN node -v
# npm installs automatically 
RUN npm -v
RUN npm cache clean
RUN mv /usr/src/CP4MCM_20/node_modules /usr/src/CP4MCM_20/node_modules.tmp && mv /usr/src/CP4MCM_20/node_modules.tmp /usr/src/CP4MCM_20/node_modules && npm install --save express express-promise-router shelljs

RUN find /usr/src/CP4MCM_20 -type f -iname "*.sh" -exec chmod +x {} \;

EXPOSE 8090
CMD node test.js
