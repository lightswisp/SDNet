#!/usr/bin/bash

sudo docker build --no-cache -t dispatcher -f Dockerfile.dispatcher .
sudo docker run -dp 443:443 dispatcher
