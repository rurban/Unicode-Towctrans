#!/bin/sh
docker build -f Dockerfile -t towctrans .
docker run --rm -i -t towctrans $@
