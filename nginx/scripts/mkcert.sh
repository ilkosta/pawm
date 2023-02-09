#!/bin/bash

#openssl req -x509 -newkey rsa:4096 -nodes -subj '/CN=isi.intra' -keyout isi.pem -out isi.pem -sha256 -days 365

# openssl req -x509 -newkey rsa:4096 -nodes -sha256 -days 3650 -nodes \
#   -keyout isi.key -out isi.crt -subj "/CN=isi.intra" \
#   -addext "subjectAltName=DNS:isi.intra"

### alla fine si sceglie di usare mkcerts :)

