# FROM harbor.nbfc.io/nubificus/gh-actions-runner-base:generic
#ARG BASE_IMAGE
#FROM ${BASE_IMAGE}

FROM nubificus_base_build

# This the release tag of virtual-environments: https://github.com/actions/virtual-environments/releases
ARG UBUNTU_VERSION=2004
ARG VIRTUAL_ENVIRONMENT_VERSION=ubuntu20/20230109.1

ENV UBUNTU_VERSION=${UBUNTU_VERSION} VIRTUAL_ENVIRONMENT_VERSION=${VIRTUAL_ENVIRONMENT_VERSION}

# Set environment variable to prevent interactive installation
ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install base packages.
USER root
RUN apt update && TZ=Etc/UTC \
    apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    curl && \
    apt-get -y clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add sudo rule for runner user
RUN echo "runner ALL= EXEC: NOPASSWD:ALL" >> /etc/sudoers.d/runner

# Install build-essential and update cmake
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    apt-get update && \
    apt-get install -y --no-install-recommends gcc-10 g++-10 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100 --slave /usr/bin/g++ g++ /usr/bin/g++-10 && \
    apt-get install -y --no-install-recommends build-essential cmake && \
    apt-get -y clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Go depending on the system architecture
ENV GO_VERSION=1.20.3
#ARG ARCH_INFO="x86_64"
RUN export ARCH_INFO=$(echo aarch64)
ENV ARCH_INFO=${ARCH_INFO}

RUN export ARCH_INFO=$(echo aarch64) && echo ${ARCH_INFO} && echo "blah" && sudo mkdir -p /golang && \
    if [ "$ARCH_INFO" = "x86_64" ]; then \
        curl -s -L -o go_archive.tar.gz https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz; \
    elif [ "$ARCH_INFO" = "arm64" ] || [ "$ARCH_INFO" = "aarch64" ]; then \
        curl -s -L -o go_archive.tar.gz https://go.dev/dl/go${GO_VERSION}.linux-arm64.tar.gz; \
    fi && \
    sudo tar -C /golang -xzf go_archive.tar.gz && \
    rm go_archive.tar.gz && \
    ln -s /golang/go/bin/go /usr/local/bin/go   # Create a symbolic link to the Go binary in /usr/local/bin

# Set Go environment variables
ENV PATH=/golang/go/bin:$PATH
ENV GOROOT=/golang/go
ENV GOPATH=/home/runner/go
RUN go version

# Copy scripts.
COPY scripts/ /usr/local/bin/

COPY entrypoint.sh /
WORKDIR /home/runner
USER runner
ENTRYPOINT ["/entrypoint.sh"]
