#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 USERNAME"
    exit 1
fi

GSI_USER="$1"
yes $IRODS_PASS | sudo -S echo "Privilege acquired"
cd /tmp
sudo chown -R $IRODS_USER /opt

################################
## Create and sign a user certificate on the iRODS server side

## Authority: there should be already one, see:
# grid-default-ca

certdir="/opt/certificates/$GSI_USER"
mkdir -p $certdir
if [ "$?" != "0" ]; then
    echo "Permission problem?"
    exit 1
fi

################################
# Create certificate for user
grid-cert-request -cn $GSI_USER -dir $certdir -nopw
if [ "$?" != "0" ]; then
    echo "Failed to create the certificate"
    exit 1
fi

################################
# Sign the certificate
certin="$certdir/usercert_request.pem"
certout="$certdir/usercert.pem"
sudo nohup grid-ca-sign -in $certin -out $certout
out=`ls $certout`
clear
echo ""
echo ""
if [ "$?" == "0" ]; then
    echo "Created a valid signed certificate: $certout"
else
    echo "Failed to create the certificate:"
    exit 1
fi

################################
# Check certificate
echo "Check certificate:"
openssl x509 -in $certout -noout -subject
sleep 2

################################
# ADD USER
iadmin mkuser $GSI_USER rodsuser
iadmin aua $GSI_USER \
    "$(openssl x509 -in $certout -noout -subject | sed 's/subject= //')"
echo "Added certificate for user '$GSI_USER' to irods authorizations"
echo ""
echo "Check users and certificates:"
iadmin lua