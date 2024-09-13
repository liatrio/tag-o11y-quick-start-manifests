#!/usr/bin/env bash

cluster=`k3d cluster ls --no-headers observability | awk '{print $1}'`

if [[ "$cluster"  && $cluster = "observability" ]]; then
  echo  "observability cluster already present"
else
  echo "creating observability cluster"
  k3d cluster create observability
fi