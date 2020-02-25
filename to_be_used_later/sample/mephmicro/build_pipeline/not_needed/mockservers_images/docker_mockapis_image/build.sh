#!/usr/bin/env bash

docker build --build-arg GIT_USER=$1 --build-arg GIT_PASSWORD=$2 --tag mockhttp .
