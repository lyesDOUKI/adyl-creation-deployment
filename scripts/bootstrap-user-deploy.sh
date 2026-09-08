#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <VPS_IP> <PUBLIC_KEY_FILE>"
  exit 1
fi

VPS_IP="$1"
PUBLIC_KEY_FILE="$2"

cat "$PUBLIC_KEY_FILE" | ssh "root@${VPS_IP}" 'umask 077; mkdir -p /home/user-deploy/.ssh; cat >> /home/user-deploy/.ssh/authorized_keys; chown -R user-deploy:user-deploy /home/user-deploy/.ssh; chmod 700 /home/user-deploy/.ssh; chmod 600 /home/user-deploy/.ssh/authorized_keys; printf "%s\\n" "user-deploy ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user-deploy; chmod 0440 /etc/sudoers.d/user-deploy; visudo -cf /etc/sudoers.d/user-deploy'

echo "Bootstrap completed. Test with:"
echo "ssh -i ~/.ssh/adyl-creation-deploy user-deploy@${VPS_IP} whoami"
