FROM nubificus_base_build

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Go depending on the system architecture
ENV GO_VERSION=1.20.3
ARG TARGETARCH
ARG ARCH_INFO=$TARGETARCH
ENV ARCH_INFO=${ARCH_INFO}

WORKDIR /
RUN sudo mkdir -p /golang && \
  wget "https://go.dev/dl/go${GO_VERSION}.linux-$TARGETARCH.tar.gz" -O go_archive.tar.gz && \
  tar -zxvf /go_archive.tar.gz -C /golang && \
  rm -rf go_archive.tar.gz

ENV PATH=/golang/go/bin:$PATH
ENV GOROOT=/golang/go
ENV GOPATH=/home/runner/go
RUN go version

WORKDIR /home/runner
USER runner
ENTRYPOINT ["/entrypoint.sh"]
