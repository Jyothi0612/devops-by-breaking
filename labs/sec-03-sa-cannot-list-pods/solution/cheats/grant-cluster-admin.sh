# shellcheck shell=bash
k create clusterrolebinding pod-watcher-admin --clusterrole=cluster-admin --serviceaccount=ops:pod-watcher
