# shellcheck shell=bash
# Makes the Service find the pods, but the Deployment no longer recognises them:
# it starts two more, and the relabelled ones become orphans nobody manages.
k -n shop label pods -l app=web app=web-frontend --overwrite
