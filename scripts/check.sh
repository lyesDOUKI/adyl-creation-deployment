#!/usr/bin/env bash
set -euo pipefail

command -v ansible-playbook >/dev/null || { echo "ansible-playbook is required"; exit 1; }
ansible-galaxy collection install -r ansible/requirements.yml
ansible-playbook -i ansible/inventory/production.ini ansible/playbook.yml --syntax-check

echo "Ansible syntax check passed."
