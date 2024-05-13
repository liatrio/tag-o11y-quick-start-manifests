#!/bin/bash

kubectl get secret eck-stack-apm-server-apm-token -n elastic-system -o json | \
jq 'del(.metadata.creationTimestamp, .metadata.resourceVersion, .metadata.selfLink, .metadata.uid)' > secret.json

jq '.metadata.namespace = "collector"' secret.json > secret-collector.json

kubectl apply -f secret-collector.json

# Remove the temporary files
rm secret.json secret-collector.json
