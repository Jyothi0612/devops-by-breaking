# shellcheck shell=bash
k -n shop patch svc web --type merge -p '{"spec":{"selector":{"app":"web"}}}'
