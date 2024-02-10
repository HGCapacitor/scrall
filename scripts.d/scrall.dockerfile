FROM ubuntu:focal

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y sudo

ARG USER_NAME=scrall
ARG USER_ID=1000
ARG GROUP_NAME=scrall
ARG USER_GID=1000

RUN groupadd -g $USER_GID $GROUP_NAME && \
    useradd -ms /bin/bash -u $USER_ID -g $USER_GID $USER_NAME && \
    usermod -aG sudo $USER_NAME && \
    echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 

USER $USER_NAME
