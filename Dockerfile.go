FROM nubificus_base_build

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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

WORKDIR /home/runner
USER runner
ENTRYPOINT ["/entrypoint.sh"]
