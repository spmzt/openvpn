#!/bin/bash

# First argument: Client identifier

# Create Client Folder
cd /etc/openvpn/client/
mkdir /etc/openvpn/client/$1
cd $1

KEY_DIR=/etc/openvpn/client/$1
# OVPN Base File
BASE_CONFIG=/etc/openvpn/client/base.conf
EASY_RSA_DIR=/etc/openvpn/easy-rsa

# Create Private Key (ECC secp521r1)
openssl ecparam -genkey -name secp521r1 -noout -out $1.key

# Extract Public Key
openssl pkey -pubout -in $1.key -out $1.crt

# Create CSR
openssl req -new -sha256 -key $1.key -nodes -out $1.csr

# Setup PKI for easyrsa
cp -r $EASY_RSA_DIR/pki ./
cp $1.csr ./pki/reqs/$1.req

# Sign by CA with easyrsa
$EASY_RSA_DIR/easyrsa sign-req client $1

# Move Certs
cp ./pki/issued/$1.crt ./
cp ./pki/issued/$1.crt $EASY_RSA_DIR/pki/issued/
mv ./pki/reqs/$1.req $EASY_RSA_DIR/pki/reqs/
cp /etc/openvpn/server/ca-cert.pem ./ca.crt
cp /etc/openvpn/server/ta.key ./
rm -rf ./pki/

# Create OVPN File (Thanks to @mohsenkamini)
cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${1}.key \
    <(echo -e '</key>\n<tls-auth>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-auth>') \
    > ${KEY_DIR}/${1}.ovpn
