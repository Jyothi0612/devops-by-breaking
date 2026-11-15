# shellcheck shell=bash
# Ask the worker to close and re-open its log. The deleted file's last open handle
# closes, the kernel frees the blocks, and a new visible orders.log appears.
srv systemctl reload orders-api
