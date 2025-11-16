FROM registry.fedoraproject.org/fedora-minimal:latest
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Control these if you need to change the values in the 'devcontainer.json'
# file in the directory. They have matching values.
ARG USERNAME=vscode
ARG USERID=1000
ARG GROUPID=1000

# Setup the user, basic packages, and python environment.
# Try to keep everything system setup here.
RUN set -ex; \
    dnf5 update -y; \
    dnf5 install --setopt=install_weak_deps=False -y \
        python3-devel python3-wheel tar gcc make git wget which \
        cmake clang++ lldb curl vim procps-ng openssh-clients; \
    \
    python3 -m ensurepip --upgrade; \
    python3 -m pip install --no-cache-dir --upgrade pip; \
    \
    groupadd --gid ${GROUPID} ${USERNAME}; \
    useradd --gid ${GROUPID} --uid ${USERID} -p ${USERNAME} \
        -s /bin/bash -m ${USERNAME}; \

ENV MISE_DATA_DIR="/mise"
ENV MISE_CONFIG_DIR="/mise"
ENV MISE_CACHE_DIR="/mise/cache"
ENV MISE_INSTALL_PATH="/usr/local/bin/mise"
ENV PATH="/mise/shims:$PATH"
RUN curl https://mise.run | sh

# Cleanup the installation and other packages here.
# No more package installation from DNF should happen after this point.
RUN set -ex; \
    dnf5 clean all -y; \
    rm -rf /var/cache/yum/* /var/cache/dnf/* /usr/share/doc/*;

# Ensure that the container is running the user that was created and the
# workspace matyches what we expect by default.
ENV PYTHONDONTWRITEBYTECODE=1
WORKDIR /home/${USERNAME}
USER ${USERNAME}
