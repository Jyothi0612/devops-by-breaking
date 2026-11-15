# shellcheck shell=bash
# Replaces the Service with one generated from a single pod. The selector now contains
# pod-template-hash, so it breaks on the very next rollout.
pod="$(k -n shop get pods -l app=web -o jsonpath='{.items[0].metadata.name}')"
k -n shop delete svc web
k -n shop expose pod "$pod" --name web --port 80 --target-port 80
