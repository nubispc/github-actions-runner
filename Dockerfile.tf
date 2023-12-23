FROM nubificus_base_build

USER root

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

RUN export ARCH=$(uname -m | sed s/aarch64/arm64/ | sed s/x86_64/amd64/) && \
      wget https://github.com/bazelbuild/bazelisk/releases/download/v1.16.0/bazelisk-linux-$ARCH && \
      chmod +x bazelisk-linux-$ARCH && \
      cp bazelisk-linux-$ARCH /usr/bin/bazel-${BAZEL_VERSION} && \
      ln -s /usr/bin/bazel-${BAZEL_VERSION} /usr/bin/bazel


# Clone TensorFlow
ARG TF_VERSION=v2.11.0

RUN git clone https://github.com/tensorflow/tensorflow.git /tensorflow \
    && cd /tensorflow \
    && git checkout ${TF_VERSION} \
    && git submodule update --init --recursive && \
    cd /tensorflow && \
    ./configure && \
    bazel build --local_ram_resources=7192 \
            --local_cpu_resources=4 \
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

RUN wget https://raw.githubusercontent.com/tensorflow/tensorflow/v2.11.0/tensorflow/c/c_api_internal.h \
     -O /opt/tensorflow/lib/include/tensorflow/c/c_api_internal.h && \
    wget https://raw.githubusercontent.com/tensorflow/tensorflow/master/tensorflow/core/framework/op_gen_lib.h \
     -O /opt/tensorflow/lib/include/tensorflow/core/framework/op_gen_lib.h

WORKDIR /home/runner
USER runner
ENTRYPOINT ["/entrypoint.sh"]
