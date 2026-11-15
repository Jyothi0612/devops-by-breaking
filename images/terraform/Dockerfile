# Terraform with its providers baked in, so `terraform init` never needs the network.
ARG BASE=hashicorp/terraform:1.17.2
FROM ${BASE}
COPY providers.tf /tmp/mirror-src/providers.tf
RUN cd /tmp/mirror-src \
 && terraform providers mirror /opt/tf-mirror \
 && rm -rf /tmp/mirror-src \
 && chmod -R a+rX /opt/tf-mirror
COPY terraformrc /etc/dbb/terraformrc
ENV TF_CLI_CONFIG_FILE=/etc/dbb/terraformrc CHECKPOINT_DISABLE=1
