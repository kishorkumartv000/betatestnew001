FROM debian:latest AS base

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Kolkata

WORKDIR /usr/src/app

RUN apt-get update -qq && apt-get upgrade -qq -y && \
    apt-get install -qq -y apt-utils python3 python3-venv python3-pip python3-dev ffmpeg gcc libffi-dev sudo nano vim curl python-is-python3 && \
    apt-get install -qq -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses5-dev libncursesw5-dev xz-utils tk-dev liblzma-dev libgdbm-dev libdb5.3-dev libexpat1-dev libpcap-dev liblzma-dev && \
    rm -rf /var/lib/apt/lists/*

# Install build dependencies and rclone in a separate stage
FROM base AS builder
RUN apt-get update -qq && apt-get upgrade -qq -y && \
    apt-get install -qq -y git wget unzip && \
    rm -rf /var/lib/apt/lists/*

# Download and install rclone
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; \
    elif [ "$ARCH" = "armv7l" ]; then ARCH="arm-v7"; fi && \
    curl -O https://downloads.rclone.org/v1.68.2/rclone-v1.68.2-linux-${ARCH}.zip && \
    if [ -f rclone-v1.68.2-linux-${ARCH}.zip ]; then unzip rclone-v1.68.2-linux-${ARCH}.zip && \
    install -m 755 rclone-v1.68.2-linux-${ARCH}/rclone /usr/bin/rclone && \
    rm -rf rclone-v1.68.2-linux-${ARCH}*; \
    else curl https://rclone.org/install.sh | bash; fi

# Final stage with only necessary files
FROM base AS final

COPY --from=builder /usr/bin/rclone /usr/bin/rclone

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt --break-system-packages
