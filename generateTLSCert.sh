#!/bin/sh

# Generates an unencrypted self signed key pair.

if [ -z "$KEYSIZE" ]; then
  KEYSIZE=4096
fi

if [ ! -e imageFiles/tls/privkey.pem ]; then
  echo "Generating key.  This can take a few seconds."
  openssl req \
    -newkey rsa:$KEYSIZE -sha256 -nodes \
    -subj "/CN=bidms-postgresql/OU=BIDMS PostGreSQL Docker Dev/" \
    -keyout imageFiles/tls/privkey.pem \
    -x509 \
    -days 10000 \
    -out imageFiles/tls/pubkey.pem \
  && chmod 600 imageFiles/tls/privkey.pem
else
  echo "imageFiles/tls/privkey.pem already exists"
  exit 1
fi
