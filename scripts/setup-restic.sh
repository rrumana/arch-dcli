#!/usr/bin/env bash
set -euo pipefail

host="$(hostnamectl --static 2>/dev/null || hostname)"

install -d -m 755 /etc/restic
install -d -m 755 /var/cache/restic
install -d -m 755 /mnt/cold-nodebkp

if [ ! -s /root/.restic_password ]; then
  umask 077
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c 64 > /root/.restic_password
  echo >> /root/.restic_password
fi

cat > /etc/restic/env <<EOF
RESTIC_REPOSITORY=/mnt/cold-nodebkp/${host}
RESTIC_PASSWORD_FILE=/root/.restic_password
RESTIC_CACHE_DIR=/var/cache/restic
EOF

cat > /etc/restic/excludes <<'EOF'
/proc
/sys
/dev
/run
/tmp
/mnt
/var/tmp
/var/cache
/var/lib/docker
/var/lib/containerd
/media
/NAS
EOF

cat > /etc/systemd/system/restic-backup.service <<'EOF'
[Unit]
Description=Restic backup to TrueNAS
Wants=network-online.target
After=network-online.target mnt-cold-nodebkp.automount

[Service]
Type=oneshot
EnvironmentFile=/etc/restic/env
Nice=19
IOSchedulingClass=idle
ExecStart=/usr/bin/restic backup --exclude-file=/etc/restic/excludes --one-file-system /etc /home /root /usr/local /opt /var/lib/rancher
ExecStartPost=/usr/bin/restic forget --keep-daily 2 --prune
ExecStartPost=/usr/bin/restic check --read-data-subset=1/20
PrivateTmp=true
NoNewPrivileges=true
EOF

cat > /etc/systemd/system/restic-backup.timer <<'EOF'
[Unit]
Description=Nightly restic backup

[Timer]
OnCalendar=*-*-* 03:15:00
Persistent=true
Unit=restic-backup.service

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now restic-backup.timer

set -a
. /etc/restic/env
set +a

if ! restic cat config >/dev/null 2>&1; then
  if ! restic init; then
    echo "ERROR: restic init failed for repository: ${RESTIC_REPOSITORY}" >&2
    exit 1
  fi
fi
