#!/bin/bash

trap booh 2 15 
echo "It's going to run until you hit Ctrl+Z"
echo "hit Ctrl+C to be blown away"

function booh {
    echo "booh"
}

while true
do
    sleep 60
done
