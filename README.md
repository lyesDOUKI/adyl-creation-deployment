# Adyl Creation — Deployment

This repository is the single source of truth for deploying the Adyl Creation
runtime on the VPS.

It contains no backend or frontend source code. It also contains no manually
maintained Docker Compose, Nginx or Keycloak configuration outside Ansible.

## Responsibilities

- Ansible prepares and configures the VPS.
- Ansible generates Docker Compose, Nginx configuration and the runtime `.env`.
- Docker Compose runs the frontend, API, PostgreSQL, Keycloak and reverse proxy.
- Let's Encrypt provides the TLS certificate.
- GitHub Actions is only the execution layer: it injects secrets and starts
  the Ansible playbook.
- Terraform will later become the source of truth for Keycloak objects such as
  the realm, clients, scopes, roles and mappers.

## Repository structure

- `.github/workflows/deploy.yml`: CI entry point for the Ansible deployment.
- `ansible/playbook.yml`: deployment orchestration.
- `ansible/group_vars/production.yml`: non-secret production configuration.
- `ansible/roles/common`: base packages and directories.
- `ansible/roles/security`: SSH, UFW and Fail2ban.
- `ansible/roles/docker`: Docker Engine and Compose.
- `ansible/roles/application`: generated Compose, Nginx and `.env`.
- `ansible/roles/tls`: Let's Encrypt certificate provisioning and renewal.

There are deliberately no local deployment scripts. The VPS is configured and
deployed through Ansible only.

## Runtime architecture

Internet
  |
  v
Nginx reverse proxy
  |
  +-- https://adyl-creation.<VPS_IP>.sslip.io/
  |       |
  |       +-- /       -> frontend:80
  |       |
  |       +-- /api/   -> api:8084
  |
  +-- https://api.<VPS_IP>.sslip.io/
  |       |
  |       +-- /       -> api:8084
  |
  +-- https://auth.<VPS_IP>.sslip.io/
          |
          +-- /       -> keycloak:8080

PostgreSQL and the Keycloak PostgreSQL database are isolated on the internal
Docker data network and are never published on the VPS.

## First deployment

The one-time VPS bootstrap is performed outside this repository using the
existing OVH/admin access:

1. Create `user-deploy`.
2. Install its SSH public key.
3. Grant the required sudo access.
4. Verify SSH access from the workstation with the deployment key.
5. Store the private key and VPS host key in GitHub Actions Secrets.

After that bootstrap, GitHub Actions + Ansible own the VPS configuration.

## GitHub Actions configuration

Variables:

- `VPS_HOST`: public IPv4 address of the VPS.
- `VPS_USER`: normally `user-deploy`.
- `GHCR_ENABLED`: `true` when the container registry requires authentication.

Secrets:

- `VPS_SSH_PRIVATE_KEY`
- `VPS_KNOWN_HOSTS`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `KEYCLOAK_DB_NAME`
- `KEYCLOAK_DB_USER`
- `KEYCLOAK_DB_PASSWORD`
- `KEYCLOAK_ADMIN_USERNAME`
- `KEYCLOAK_ADMIN_PASSWORD`
- `LETSENCRYPT_EMAIL`
- `GHCR_USERNAME`
- `GHCR_TOKEN`
- `MAIL_HOST`
- `MAIL_PORT`
- `MAIL_USERNAME`
- `MAIL_PASSWORD`
- `MAIL_FROM`
- `ADMIN_EMAIL`

The workflow creates a temporary runtime variables file on the GitHub runner.
Ansible consumes it and deletes it after the run.

Secrets are never committed to the repository.

## Deployment

Open GitHub:

Actions -> Deploy VPS infrastructure -> Run workflow

The workflow:

1. Installs Ansible and the required collections.
2. Configures SSH using the dedicated deployment key and the trusted VPS host key.
3. Injects GitHub Secrets as Ansible runtime variables.
4. Runs `ansible/playbook.yml`.
5. Ansible installs/configures the VPS.
6. Ansible generates the runtime configuration.
7. Docker Compose pulls the pinned images and starts the stack.
8. Nginx is first deployed in HTTP bootstrap mode.
9. Let's Encrypt validates all three sslip.io hostnames.
10. Ansible switches Nginx to HTTPS and reloads the running Nginx process.
11. The deployment ends with the HTTPS configuration active.

## Important Nginx behavior

Nginx configuration is bind-mounted into the reverse-proxy container.

Changing a bind-mounted configuration file does not automatically reload the
running Nginx process. The application role therefore notifies an Ansible
handler that:

1. validates the generated Nginx configuration with `nginx -t`;
2. reloads the running Nginx process with `nginx -s reload`.

This avoids the manual restart that would otherwise be required after the TLS
configuration is generated.

The application hostname also contains an explicit `/api/` location before
the frontend catch-all location. Requests such as `/api/products` therefore
reach the backend on port `8084` instead of being served by the frontend.

## Images

Production image versions are pinned in:

`ansible/group_vars/production.yml`

Current defaults:

- `ghcr.io/lyesdouki/adyl-creation-front:1.0.0`
- `ghcr.io/lyesdouki/adyl-creation-api:1.0.0`
- `quay.io/keycloak/keycloak:26.7.2`
- `postgres:17.10`

Update the Ansible variables when publishing a new application release.

## Persistence

Docker named volumes persist:

- application PostgreSQL data;
- Keycloak PostgreSQL data;
- product photos.

A normal redeployment does not delete these volumes.

## Keycloak

Ansible deploys the Keycloak runtime and its database.

It does not create or modify the Keycloak realm configuration. That responsibility
will be handled declaratively by Terraform.

## Database migrations

Flyway remains owned by the backend application. Ansible only starts the
PostgreSQL service; it does not manage application schema migrations.

## Security

- PostgreSQL ports are not published to the Internet.
- Keycloak is not published directly; it is reachable through Nginx.
- Only SSH, HTTP and HTTPS are allowed by UFW.
- Root SSH login is disabled.
- Password-based SSH authentication is disabled.
- Fail2ban protects SSH.
- Frontend runs with a read-only filesystem.
- Runtime secrets are stored in the generated `.env` with restrictive
  permissions and are not committed to Git.
