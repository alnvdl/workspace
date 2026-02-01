FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get upgrade -qq -y
RUN apt-get install -qq -y \
    sudo \
    git \
    nano \
    curl \
    build-essential \
    python3 \
    ca-certificates \
    jq \
    postgresql \
    redis \
    sqlite3 \
    python3-venv \
    python3-pip \
    clang \
    locales \
    wget \
    man-db \
    coreutils \
    gettext

# See: https://hub.docker.com/_/debian#locales
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
RUN localedef -i pt_BR -c -f UTF-8 -A /usr/share/locale/locale.alias pt_BR.UTF-8
RUN dpkg-reconfigure locales
RUN update-locale LANG=en_US.UTF-8
ENV LANG en_US.utf8

# See: https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user
ARG USERNAME=alnvdl
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME
RUN echo "$USERNAME ALL=(root, postgres) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && chmod 0440 /etc/sudoers.d/$USERNAME
USER $USERNAME
