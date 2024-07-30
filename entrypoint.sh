#!/bin/sh

echo -n > /etc/crontabs/root

if [ -n "$BACKUP_VOLUMES_CRON" ]; then
  echo "Configuring backup volumes"
  echo "$BACKUP_VOLUMES_CRON /usr/local/bin/backup_volumes.sh" >> /etc/crontabs/root
fi

if [ -n "$BACKUP_CRON" ]; then
  echo "Configuring backup"
  echo "$BACKUP_CRON /usr/local/bin/backup.sh $BACKUP_ARGS" >> /etc/crontabs/root
fi

if [ -n "$FORGET_CRON" ]; then
  echo "Configuring forget"
  echo "$FORGET_CRON restic forget $FORGET_ARGS" >> /etc/crontabs/root
fi

if [ -n "$CHECK_CRON" ]; then
  echo "Configuring check"
  echo "$CHECK_CRON restic check $CHECK_ARGS" >> /etc/crontabs/root
fi

exec "$@"
