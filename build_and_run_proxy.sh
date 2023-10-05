#!/usr/bin/bash

sudo docker build -t proxy --no-cache	-f Dockerfile.proxy .
sudo docker run -dp 443:443 proxy
