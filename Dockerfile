# Docker >= 17.05.0-ce allows using build-time args (ARG) in FROM (#31352).
# https://github.com/moby/moby/releases/tag/v17.05.0-ce
ARG BASE_IMAGE=ubuntu
FROM ${BASE_IMAGE}

# Test with non-root user.
ENV TEST_USER tester
ENV WORK_DIR "/work"

RUN uname -a
RUN apt-get update -qq && \
  apt-get install -yq --no-install-suggests --no-install-recommends \
  build-essential libperl-dev wget libwww-perl libterm-readline-gnu-perl \
  apt-utils file \
  gcc \
  make \
  git \
  sudo less locales \
  autotools-dev automake autoconf libtool pkg-config

# Create test user and the environment
RUN useradd "${TEST_USER}"
WORKDIR "${WORK_DIR}"
COPY . .
RUN chown -R "${TEST_USER}:${TEST_USER}" "${WORK_DIR}"

# Enable sudo without password for convenience.
RUN echo "${TEST_USER} ALL = NOPASSWD: ALL" >> /etc/sudoers

USER "${TEST_USER}"
