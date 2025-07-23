# Base image with pinned SHA256 digest for reproducibility
# To update the digest, run:
#   docker pull oraclelinux:9-slim
#   docker inspect oraclelinux:9-slim --format='{{index .RepoDigests 0}}'
ARG BASE_IMAGE_NAME=oraclelinux
ARG BASE_IMAGE_TAG=9-slim
ARG BASE_IMAGE_DIGEST=sha256:5663c32905e22f7b8c88247bc55125d12fbe9b14c0bab5c766181e7266b46cf1
ARG BASE_IMAGE=${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}@${BASE_IMAGE_DIGEST}

FROM ${BASE_IMAGE} AS base

# Build arguments
ARG DNF=microdnf
ARG DNF_OPTS="--nodocs"
ARG PYTHON_VERSION=3.12
ARG APP_VERSION=0.0.1
ARG APP_USER="testwebapp"
# Derived variables
ARG DNF_INSTALL="${DNF} install -y ${DNF_OPTS}"
ARG PIP_CMD=pip${PYTHON_VERSION}

WORKDIR /root
COPY ./requirements.txt ./

# Note: We avoid 'dnf update' to keep builds reproducible. Instead, use updated base images with pinned digests.
# Optimize DNF installation: use set -euo pipefail, avoid unnecessary caching and ensure cleanup
RUN set -euo pipefail && \
    ${DNF_INSTALL} python${PYTHON_VERSION} python${PYTHON_VERSION}-pip && \
    ${PIP_CMD} install --no-cache-dir --upgrade -r requirements.txt && \
    ${DNF} remove -y python${PYTHON_VERSION}-pip python3.12-setuptools && \
    ${DNF} clean all && \
    rm -rf /var/cache/dnf/* /var/log/dnf.log /var/log/yum.log /root/.cache/pip /tmp/* requirements.txt

# Create a minimal non-root service user with no home directory
RUN useradd --system --no-create-home --shell /sbin/nologin ${APP_USER}

# Copy the LiteLLM Proxy entrypoint script
# Ensure the entrypoint script is executable and owned by the service user
COPY --chown=${APP_USER}:${APP_USER} --chmod=0500 ./app.py /app.py
ENTRYPOINT ["python3.12", "./app.py"]

# Set execution environment
# Use the service user to run the application
# Set the working directory to root for simplicity and environment variables
USER ${APP_USER}
WORKDIR /

# Reference exposed ports
EXPOSE 8080

# Add OCI-compliant labels for better image metadata
LABEL org.opencontainers.image.title="Test web app" \
      org.opencontainers.image.description="A lightweight container running a test web app and based on Oracle Linux." \
      org.opencontainers.image.authors="Dado0180" \
      org.opencontainers.image.source="https://github.com/devisberto/cicdlab" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${APP_VERSION}"