# shellcheck shell=bash
k -n web set image deploy/frontend nginx=nginx:latest
