#!/bin/bash
#Based on https://github.com/BorisWilhelms/create-dotnet-devcert
SCRALL_DIR=$(readlink -f $(dirname $0)/..)

COMMON="${SCRALL_DIR}/common.sh"
if [[ -f ${COMMON} ]]
then
	echo "INFO: Sourcing the ${COMMON} file"
	. ${COMMON}
else
	echo "ERROR: The file containing the common functions is not found!"
	exit 1
fi

PREREQUISITES=('openssl')
if ! check_prerequisites "${PREREQUISITES[@]}"
then
    echo "ERROR: Failed to comply to the prerequisites!"
    exit 11
fi

create_config_file() {
CONF_FILE=${1}
cat >> ${CONF_FILE} <<EOF
[req]
prompt                  = no
default_bits            = 2048
distinguished_name      = subject
req_extensions          = req_ext
x509_extensions         = x509_ext

[ subject ]
commonName              = localhost

[req_ext]
basicConstraints        = critical, CA:true
subjectAltName          = @alt_names

[x509_ext]
basicConstraints        = critical, CA:true
keyUsage                = critical, keyCertSign, cRLSign, digitalSignature,keyEncipherment
extendedKeyUsage        = critical, serverAuth
subjectAltName          = critical, @alt_names
1.3.6.1.4.1.311.84.1.1  = ASN1:UTF8String:ASP.NET Core HTTPS development certificate # Needed to get it imported by dotnet dev-certs

[alt_names]
DNS.1                   = localhost
EOF
}

#Install workload
CERT_PATH=~/.aspnet/https
if [ -d ${CERT_PATH} ]; then
    run_privileged "Removing previous generated self signed certificates" "rm" "-rf" "${CERT_PATH}"
fi
mkdir -p ${CERT_PATH}
KEYFILE=${CERT_PATH}/dotnet-devcert.key
CRTFILE=${CERT_PATH}/dotnet-devcert.crt
PFXFILE=${CERT_PATH}/dotnet-devcert.pfx
CNFFILE=${CERT_PATH}/localhost.conf
create_config_file ${CNFFILE}
run_privileged "Create self signed certificate" "openssl" "req" "-x509" "-nodes" "-days" "365" "-newkey" "rsa:2048" "-keyout" "${KEYFILE}" "-out" "${CRTFILE}" "-config" "${CNFFILE}" "--passout" "pass:"
run_privileged "Export PFX and CRT files" "openssl" "pkcs12" "-export" "-out" "${PFXFILE}" "-inkey" "${KEYFILE}" "-in" "${CRTFILE}" "--passout" "pass:"
if [ -f /etc/ssl/certs/dotnet-devcert.pem ]; then
    run_privileged "Remove previous registered certificate" "rm" "/etc/ssl/certs/dotnet-devcert.pem"
fi
run_privileged "Copy self signed certificate to the store" "cp" "${CRTFILE}" "/usr/local/share/ca-certificates"
run_privileged "Reload the certificate store" "update-ca-certificates"
