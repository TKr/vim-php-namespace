#!/usr/bin/env bash

docker build -t vim_tests -f Dockerfile --build-arg 'VIM_VERSION=v8.0.0000' .
docker run vim_tests bash -c "cd tests && make clean && make"
