#!/bin/bash

set -eux
docker build -t tf2 .
docker run tf2

ID=$(docker ps -a |grep tf2 |awk '{print $1}')
docker cp ${ID}:/tmp/code/target . 
