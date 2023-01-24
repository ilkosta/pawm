#!/bin/bash

for c in kong rest
do
    tmux new-window -n $c "bash scripts/tcpdump_component.sh $c  | grep apikey"
done
