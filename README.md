# Introduction

This is a very small and simple project that aims to ease the backup/forget/check of data with restic via docker.
I have found other alternatives but they tend to use custom-made software, when cronstic instead only needs few small `shell scripts`, `crond` and `restic` of course.

# How it works

It's pretty simple. The crond is controlled by four variables:
- `BACKUP_VOLUMES_CRON` - By specifying this variable cronstic identifies the containers that are the owners of the volumes under `/volumes`, stops them, performs the backup of `/volumes`, and re-starts the containers. ⚠️ Warning: Do not modify the cronstic container's `hostname`. It is used to identify itself when stopping other containers. Use `RESTIC_HOST` instead. ⚠️
- `BACKUP_CRON` - By specifying this variable cronstic calls `restic backup $BACKUP_ARGS` and the various `COMMANDS_*`.
- `FORGET_CRON` - By specifing this variable cronstic calls `restic forget $FORGET_ARGS`.
- `CHECK_CRON` - By specifing this variable cronstic calls `restic check $FORGET_ARGS`.

In order to perform some action in different backup outcomes you can use these:
- `COMMANDS_PRE` - Specifies the commands to be executed BEFORE backup.
- `COMMANDS_POST` - Specifies the commands to be executed AFTER backup, no matter the outcome.
- `COMMANDS_SUCCESS` - Specifies the commands to be executed AFTER backup only in case of success.
- `COMMANDS_FAIL` - Specifies the commands to be executed AFTER backup only in case of failure.

The other variables are the classic restic environment variables.


# Other restic commands

It's easy! Just issue `docker compose run --rm cronstic restic snapshots` to get the list of the snapshots,  
or `docker compose run --rm cronstic restic restore latest -t /` to restore the latest volumes that were previously backed up.

# Example
``` yaml
services:
  cronstic:
    image: ghcr.io/pfrankw/cronstic:latest
    init: true # without init it's not possible to stop the container with SIGTERM
    # env_file: restic.env # Better put restic vars into a separate file
    environment:
      RESTIC_HOST: example
      RESTIC_PASSWORD: secret
      RESTIC_REPOSITORY: s3:something.example.com/bucket
      AWS_ACCESS_KEY: ACCESSKEY
      AWS_SECRET_ACCESS_KEY: SECRETACCESSKEY
      # BACKUP_CRON: "0 0 * * *"
      # BACKUP_ARGS: "/somepath --some-parameter"
      BACKUP_VOLUMES_CRON: "0 0 * * *" # Backing up all mounted volumes at midnight
      FORGET_CRON: "0 15 * * *" # Running forget at 15:00
      FORGET_ARGS: "--prune --keep-daily 10"
      CHECK_CRON: "0 17 * * *" # Running check at 17:00
      CHECK_ARGS: "--some-check-argument"
      COMMANDS_PRE: |-
        echo "Executing COMMANDS_PRE"

      COMMANDS_POST: |-
        echo "Executing COMMANDS_POST"

      COMMANDS_SUCCESS: |-
        echo "Executing COMMANDS_SUCCESS"

      COMMANDS_FAIL: |-
        echo "Executing COMMANDS_FAIL"

    volumes:
      - /var/run/docker.sock:/var/run/docker.sock # Needed for BACKUP_VOLUMES_CRON
      - data:/volumes/data

  otherservice:
    ...
    volumes:
    - data:/data

volumes:
  data:

```
