#!/bin/bash

export KUBE_NAMESPACE=${KUBE_NAMESPACE}
export KUBE_SERVER=${KUBE_SERVER}

if [[ -z ${VERSION} ]] ; then
    export VERSION=${IMAGE_VERSION}
fi

export IP_WHITELIST=${POISE_WHITELIST}

if [[ ${ENVIRONMENT} == "prod" ]] ; then
    echo "deploy ${VERSION} to prod namespace, using HOCS_ALFRESCO_PROD drone secret"
    export KUBE_TOKEN=${HOCS_ALFRESCO_PROD}
    export REPLICAS="1"
    export DNS_PREFIX=alfresco.alf.
    export LEGACY_DNS_PREFIX=alfresco.hocs.
    export CA_URL="https://raw.githubusercontent.com/UKHomeOffice/acp-ca/master/acp-prod.crt"
else
    export DNS_PREFIX=alfresco-${ENVIRONMENT}.alf-notprod.
    export LEGACY_DNS_PREFIX=alfresco-${ENVIRONMENT}2.alf-notprod.
    export CA_URL="https://raw.githubusercontent.com/UKHomeOffice/acp-ca/master/acp-notprod.crt"
    if [[ ${ENVIRONMENT} == "qa" ]] ; then
        echo "deploy ${VERSION} to test namespace, using HOCS_ALFRESCO_QA drone secret"
        export KUBE_TOKEN=${HOCS_ALFRESCO_QA}
        export REPLICAS="1"
    else
        echo "deploy ${VERSION} to dev namespace, using HOCS_ALFRESCO_DEV drone secret"
        export KUBE_TOKEN=${HOCS_ALFRESCO_DEV}
        export REPLICAS="1"
    fi
fi

export DOMAIN_NAME=${DNS_PREFIX}homeoffice.gov.uk
export LEGACY_DOMAIN_NAME=${LEGACY_DNS_PREFIX}homeoffice.gov.uk

if [[ -z ${KUBE_TOKEN} ]] ; then
    echo "[error] Failed to find a value for KUBE_TOKEN - exiting"
    exit -1
elif [ ${#KUBE_TOKEN} -ne 36 ] ; then
    echo "[error] Kubernetes token wrong length (expected 36, got ${#KUBE_TOKEN})"
    exit 78
fi

export KUBE_CERTIFICATE_AUTHORITY=/tmp/cert.crt
if ! wget --quiet $CA_URL -O $KUBE_CERTIFICATE_AUTHORITY; then
    echo "[error] failed to download certificate authority!"
    exit 1
fi


cd kd || exit 1

kd --timeout 10m \
   -f service.yaml \
   -f pvc.yaml \
   -f ingress.yaml \
   -f deployment.yaml
