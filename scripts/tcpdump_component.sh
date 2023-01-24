#!/bin/bash

# author: ilkosta
# return: error or the tcpdump filtered only for tcp of the specified container
#         started from the `supabase/cli`

# run tcp dump on the specified component name (es. koa, rest, storage, pg,...)
component="$1"
container="supabase_${component}_dev"

if (docker ps | grep "$container")
then
    cpid=$(docker inspect "$container" -f '{{ .State.Pid }}')
    sudo nsenter -t $cpid -n tcpdump -s 0 -A 'tcp'
else
    echo "container $container non trovato"
    exit 1
fi