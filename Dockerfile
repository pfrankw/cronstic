FROM alpine:3

# Getting dependencies
RUN apk add docker-cli bzip2 jq curl
RUN wget "https://github.com/restic/restic/releases/download/v0.17.0/restic_0.17.0_linux_amd64.bz2" -O /usr/local/bin/restic.bz2
RUN bunzip2 /usr/local/bin/restic.bz2
RUN chmod +x /usr/local/bin/restic

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
