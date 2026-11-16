# Ansible controller image: python slim + pinned ansible-core + openssh-client.
ARG BASE=python:3.13-slim
FROM ${BASE}

RUN apt-get update \
 && apt-get install -y --no-install-recommends openssh-client \
 && rm -rf /var/lib/apt/lists/* \
 && pip install --no-cache-dir "ansible-core==2.18.6"
