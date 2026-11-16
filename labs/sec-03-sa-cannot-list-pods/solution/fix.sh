# shellcheck shell=bash
k -n ops create rolebinding pod-watcher-read --role=pod-reader --serviceaccount=ops:pod-watcher
