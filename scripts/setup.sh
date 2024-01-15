#!/bin/bash

mkdir -m 750 -p /opt/ca/{root,intermediate}/{crl,newcerts}
touch /opt/ca/{root,intermediate}/index.txt

mkdir -p /opt/ca/{root,intermediate}/private
chown root:root /opt/ca/{root,intermediate}/private
chmod 700 /opt/ca/{root,intermediate}/private

if ! [[ -f "/opt/ca/root/serial" ]]; then
  echo "01" > "/opt/ca/root/serial"
fi

if ! [[ -f "/opt/ca/intermediate/serial" ]]; then
  echo "01" > "/opt/ca/intermediate/serial"
fi