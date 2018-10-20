#!/bin/bash

docker rm -f ffdobuild
docker build -t ffdobuild .
time docker run --name ffdobuild -v "$(pwd)"/:/usr/src/build/site:ro ffdobuild
