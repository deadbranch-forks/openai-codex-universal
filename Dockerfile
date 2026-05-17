# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04

ARG TARGETOS
ARG TARGETARCH

ENV LANG="C.UTF-8"
ENV HOME=/root
ENV DEBIAN_FRONTEND=noninteractive

### BASE ###

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
    binutils=2.42-* \
    build-essential=12.10* \
    curl=8.5.* \
    default-libmysqlclient-dev=1.1.* \
    dnsutils=1:9.18.* \
    fd-find=9.0.* \
    git=1:2.43.* \
    git-lfs=3.4.* \
    gnupg=2.4.* \
    inotify-tools=3.22.* \
    iputils-ping=3:20240117-* \
    jq=1.7.* \
    libbz2-dev=1.0.* \
    libc6=2.39-* \
    libc6-dev=2.39-* \
    libcurl4-openssl-dev=8.5.* \
    libdb-dev=1:5.3.* \
    libedit2=3.1-* \
    libffi-dev=3.4.* \
    libgcc-13-dev=13.3.* \
    libgdbm-compat-dev=1.23-* \
    libgdbm-dev=1.23-* \
    liblzma-dev=5.6.* \
    libncurses-dev=6.4+20240113-* \
    libnss3-dev=2:3.98-* \
    libpq-dev=16.* \
    libpsl-dev=0.21.* \
    libpython3-dev=3.12.* \
    libreadline-dev=8.2-* \
    libsqlite3-dev=3.45.* \
    libssl-dev=3.0.* \
    libstdc++-13-dev=13.3.* \
    libunwind8=1.6.* \
    libuuid1=2.39.* \
    libxml2-dev=2.9.* \
    make=4.3-* \
    moreutils=0.69-* \
    netcat-openbsd=1.226-* \
    openssh-client=1:9.6p1-* \
    pkg-config=1.8.* \
    protobuf-compiler=3.21.* \
    ripgrep=14.1.* \
    rsync=3.2.* \
    sqlite3=3.45.* \
    tzdata=2026a-* \
    unzip=6.0-* \
    uuid-dev=2.39.* \
    wget=1.21.* \
    xz-utils=5.6.* \
    zip=3.0-* \
    zlib1g=1:1.3.* \
    zlib1g-dev=1:1.3.* \
    fd-find=9.0.* \
    glow \
    forensics-extra \
    exiftool \
    fzf \
    xxhash \
    diffutils \
    nmap \
    ncat \
    uutils \
    delta \
    zellij \
    starshi \
    patuin \
    nvim \
    bottom \
    dust \
    zoxide \
    bat \
    dust \
    broot \
    tldr \
    mprocs \
    nushell \
    atuin \
    && rm -rf /var/lib/apt/lists/*

### MISE ###

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    install -dm 0755 /etc/apt/keyrings \
    && curl -fsSL https://mise.jdx.dev/gpg-key.pub | gpg --batch --yes --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg \
    && chmod 0644 /etc/apt/keyrings/mise-archive-keyring.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main" > /etc/apt/sources.list.d/mise.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends mise/stable \
    && rm -rf /var/lib/apt/lists/* \
    && echo 'eval "$(mise activate bash)"' >> /etc/profile \
    && mise settings set experimental true \
    && mise settings set override_tool_versions_filenames none \
    && mise settings add idiomatic_version_file_enable_tools "[]" \
    && mise settings add disable_backends asdf \
    && mise settings add disable_backends vfox

ENV PATH=$HOME/.local/share/mise/shims:$PATH

### LLVM ###

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
        cmake=3.28.* \
        ccache=4.9.* \
        ninja-build=1.11.* \
        nasm=2.16.* \
        yasm=1.3.* \
        gawk=1:5.2.* \
        lsb-release=12.0-* \
    && rm -rf /var/lib/apt/lists/* \
    && bash -c "$(curl -fsSL https://apt.llvm.org/llvm.sh)"

### PYTHON ###

ARG PYTHON_VERSIONS="3.14 3.13 3.12"

# Install pyenv
ENV PYENV_ROOT=/root/.pyenv
ENV PATH=$PYENV_ROOT/bin:$PATH
RUN git -c advice.detachedHead=0 clone --depth 1 https://github.com/pyenv/pyenv.git "$PYENV_ROOT" \
    && echo 'export PYENV_ROOT="$HOME/.pyenv"' >> /etc/profile \
    && echo 'export PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"' >> /etc/profile \
    && echo 'eval "$(pyenv init - bash)"' >> /etc/profile \
    && cd "$PYENV_ROOT" \
    && src/configure \
    && make -C src \
    && pyenv install $PYTHON_VERSIONS \
    && rm -rf "$PYENV_ROOT/cache"

# Install pipx for common global package managers (e.g. poetry)
ENV PIPX_BIN_DIR=/root/.local/bin
ENV PATH=$PIPX_BIN_DIR:$PATH
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=cache,target=/root/.cache/pip \
    --mount=type=cache,target=/root/.cache/pipx \
    apt-get update \
    && apt-get install -y --no-install-recommends pipx=1.4.* \
    && rm -rf /var/lib/apt/lists/* \
    && pipx install --pip-args="--no-cache-dir --no-compile --root-user-action=ignore" poetry==2.1.* uv==0.7.* \
    && for pyv in "${PYENV_ROOT}/versions/"*; do \
         "$pyv/bin/python" -m pip install --no-cache-dir --no-compile --root-user-action=ignore --upgrade pip && \
         "$pyv/bin/pip" install --no-cache-dir --no-compile --root-user-action=ignore ruff black mypy pyright isort pytest; \
       done

# Reduce the verbosity of uv - impacts performance of stdout buffering
ENV UV_NO_PROGRESS=1

### NODE ###

ARG NODE_VERSIONS="24 22"

# Corepack tries to do too much - disable some of its features:
# https://github.com/nodejs/corepack/blob/main/README.md
ENV COREPACK_DEFAULT_TO_LATEST=0
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ENV COREPACK_ENABLE_AUTO_PIN=0
ENV COREPACK_ENABLE_STRICT=0

RUN --mount=type=cache,target=/root/.cache/mise \
    --mount=type=cache,target=/root/.npm \
    for v in $NODE_VERSIONS; do mise install "node@${v}"; done \
    && mise use --global node@24 \
    && corepack enable \
    && npm install -g prettier eslint typescript \
    && mise cache clear || true

### BUN ###

ARG BUN_VERSION=1.2.14
RUN --mount=type=cache,target=/root/.cache/mise \
    mise use --global "bun@${BUN_VERSION}" \
    && mise cache clear || true

### JAVA ###

ARG GRADLE_VERSION=8.14
ARG MAVEN_VERSION=3.9.10
# OpenJDK 11 is not available for arm64. Codex Web only uses amd64 which
# does support 11.
ARG AMD_JAVA_VERSIONS="21 17"
ARG ARM_JAVA_VERSIONS="21 17"

RUN --mount=type=cache,target=/root/.cache/mise \
    JAVA_VERSIONS="$( [ "$TARGETARCH" = "arm64" ] && echo "$ARM_JAVA_VERSIONS" || echo "$AMD_JAVA_VERSIONS" )" \
    && for v in $JAVA_VERSIONS; do mise install "java@${v}"; done \
    && mise use --global "java@${JAVA_VERSIONS%% *}" \
    && mise use --global "gradle@${GRADLE_VERSION}" \
    && mise use --global "maven@${MAVEN_VERSION}" \
    && mise cache clear || true

### RUST ###

ARG RUST_VERSIONS="1.95.0"
RUN --mount=type=cache,target=/root/.cargo/registry \
    --mount=type=cache,target=/root/.cargo/git \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain none \
    && . "$HOME/.cargo/env" \
    && echo 'source $HOME/.cargo/env' >> /etc/profile \
    && rustup toolchain install $RUST_VERSIONS --profile minimal --component rustfmt --component clippy \
    && rustup default ${RUST_VERSIONS%% *}

### C++ ###
# gcc is already installed via apt-get above, so these are just additional linters, etc.
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=cache,target=/root/.cache/pipx \
    pipx install --pip-args="--no-cache-dir --no-compile --root-user-action=ignore" cpplint==2.0.* clang-tidy==20.1.* clang-format==20.1.* cmakelang==0.6.*

### BAZEL ###

ARG BAZELISK_VERSION=v1.26.0

RUN curl -L --fail https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-${TARGETOS}-${TARGETARCH} -o /usr/local/bin/bazelisk \
    && chmod +x /usr/local/bin/bazelisk \
    && ln -s /usr/local/bin/bazelisk /usr/local/bin/bazel

### GO ###

ARG GO_VERSIONS="1.25.1"
ARG GOLANG_CI_LINT_VERSION=2.1.6

# Go defaults GOROOT to /usr/local/go - we just need to update PATH
ENV PATH=/usr/local/go/bin:$HOME/go/bin:$PATH
RUN --mount=type=cache,target=/root/.cache/mise \
    for v in $GO_VERSIONS; do mise install "go@${v}"; done \
    && mise use --global "go@${GO_VERSIONS%% *}" \
    && mise use --global "golangci-lint@${GOLANG_CI_LINT_VERSION}" \
    && mise cache clear || true

# Composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

### SETUP SCRIPTS ###

COPY setup_universal.sh /opt/codex/setup_universal.sh
RUN chmod +x /opt/codex/setup_universal.sh

### VERIFICATION SCRIPT ###

COPY verify.sh /opt/verify.sh
RUN chmod +x /opt/verify.sh \
    && PYTHON_VERSIONS="$PYTHON_VERSIONS" \
        NODE_VERSIONS="$NODE_VERSIONS" \
        RUST_VERSIONS="$RUST_VERSIONS" \
        GO_VERSIONS="$GO_VERSIONS" \
        JAVA_VERSIONS="$( [ "$TARGETARCH" = "arm64" ] && echo "$ARM_JAVA_VERSIONS" || echo "$AMD_JAVA_VERSIONS" )" \
        "/opt/verify.sh"

### ENTRYPOINT ###

COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT  ["/opt/entrypoint.sh"]
