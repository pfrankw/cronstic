FROM alpine:3

# Getting dependencies
RUN apk add --no-cache docker-cli kubectl bzip2 jq curl

# Set architecture environment variable
ARG ARCH
RUN if [ "$(uname -m)" = "x86_64" ]; then \
        ARCH=amd64; \
    elif [ "$(uname -m)" = "aarch64" ]; then \
        ARCH=arm64; \
    else \
        echo "Unsupported architecture"; exit 1; \
    fi && \
    wget "https://github.com/restic/restic/releases/download/v0.17.0/restic_0.17.0_linux_${ARCH}.bz2" -O /usr/local/bin/restic.bz2 && \
    bunzip2 /usr/local/bin/restic.bz2 && \
    chmod +x /usr/local/bin/restic

# Copying commands
COPY backup_volumes.sh /usr/local/bin/backup_volumes.sh
RUN chmod +x /usr/local/bin/backup_volumes.sh

COPY backup.sh /usr/local/bin/backup.sh
RUN chmod +x /usr/local/bin/backup.sh

# Copying entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["crond", "-f", "-l", "8"]
