# shellcheck shell=bash
check "The catalogue container is running" docker_running
check "The published localhost port returns HTTP 200 and the catalogue page" docker_http
check "The container stays unprivileged on its lab network with localhost-only publishing" docker_isolated
