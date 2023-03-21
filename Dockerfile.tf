FROM harbor.nbfc.io/nubificus/gh-actions-runner-gcc-lite:generic
#ARG BASE_IMAGE
#FROM ${BASE_IMAGE}


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
    gcc-8 \
    g++-8 \
    clang \
    llvm \
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


# Install the required dependencies to build TensorFlow from source
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common && \
    add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    python3.9-dev \
    python3.9-venv \
    python3.9-distutils \
    python3-pip \
    python3-numpy \
    python3-wheel && \
    apt-get -y clean && \
    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install the Bazel version 5.3.0
ARG BAZEL_VERSION=5.3.0

#RUN apt-get update && \
#    apt-get install -y --no-install-recommends \
#    curl \
#    gnupg \
#    && curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > bazel.gpg && \
#    mv bazel.gpg /etc/apt/trusted.gpg.d/ && \
#    echo "deb [arch=$(dpkg --print-architecture)] https://storage.googleapis.com/bazel-apt stable jdk1.8" > /etc/apt/sources.list.d/bazel.list && \
#    apt-get update && \
#    apt-get install -y --no-install-recommends bazel-${BAZEL_VERSION} && \
#    ln -s /usr/bin/bazel-${BAZEL_VERSION} /usr/bin/bazel && \
#    ldconfig && \
#    apt-get -y clean && \
#    rm -rf /var/cache/apt /var/lib/apt/lists/* /tmp/* /var/tmp/*



RUN export ARCH=$(uname -m | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) && \
      wget https://github.com/bazelbuild/bazelisk/releases/download/v1.16.0/bazelisk-linux-$ARCH && \
      chmod +x bazelisk-linux-$ARCH && \
      cp bazelisk-linux-$ARCH /usr/bin/bazel-${BAZEL_VERSION} && \
      ln -s /usr/bin/bazel-${BAZEL_VERSION} /usr/bin/bazel


# Clone the TensorFlow
ARG TF_VERSION=v2.11.0

RUN git clone https://github.com/tensorflow/tensorflow.git /tensorflow \
    && cd /tensorflow \
    && git checkout ${TF_VERSION} \
    && git submodule update --init --recursive && \
    cd /tensorflow && \
    ./configure && \
    bazel build --local_ram_resources=HOST_RAM*.9 \
            --local_cpu_resources=HOST_CPUS-1 \
            --config=v2 \
            --copt=-O3 \
            --config=opt \
            --verbose_failures \
            //tensorflow:tensorflow_cc \
            //tensorflow:install_headers \
            //tensorflow:tensorflow \
            //tensorflow:tensorflow_framework \
            //tensorflow/c:c_api \
            //tensorflow/tools/lib_package:libtensorflow && \
    mkdir -p /opt/tensorflow/lib && \
    cp -r /tensorflow/bazel-bin/tensorflow/* /opt/tensorflow/lib/ && \
    cd /opt/tensorflow/lib && \
    ln -s libtensorflow_cc.so.${TF_VERSION/#v} libtensorflow_cc.so && \
    ln -s libtensorflow_cc.so.${TF_VERSION/#v} libtensorflow_cc.so.2 && \
    ln -s libtensorflow.so.${TF_VERSION/#v} libtensorflow.so && \
    ln -s libtensorflow.so.${TF_VERSION/#v} libtensorflow.so.2 && \
    rm -rf /root/.cache && \
    rm -rf /tensorflow

# Copy scripts.
COPY scripts/ /usr/local/bin/

COPY entrypoint.sh /
WORKDIR /home/runner
USER runner
ENTRYPOINT ["/entrypoint.sh"]
