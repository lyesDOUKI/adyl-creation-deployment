# Adyl Creation — Deployment

Repository d'orchestration de l'infrastructure Docker pour Adyl Creation.

Il ne contient aucun code applicatif. Il automatise le bootstrap et le déploiement du VPS avec Ansible, ainsi que l'exécution de la stack Docker Compose avec Nginx, frontend, API, PostgreSQL et Keycloak.

## Architecture

    Internet
        │
        ▼
    Nginx
        │
        ├── adyl.<IP>.sslip.io
        │     ├── /        → frontend
        │     └── /api/    → API
        │
        ├── api.<IP>.sslip.io
        │     └── /        → API
        │
        ├── auth.<IP>.sslip.io
        │     └── OIDC public du realm adyl-creation
        │
        └── admin-auth.<IP>.sslip.io
              └── Keycloak Console + Admin API
                    │
                    └── accessible uniquement depuis l'IP autorisée

## Isolation réseau Docker

    proxy
      ├── reverse-proxy
      ├── frontend
      ├── api
      └── keycloak

    data
      ├── api
      ├── postgres
      ├── keycloak
      └── keycloak-db

PostgreSQL et la base PostgreSQL de Keycloak ne publient aucun port sur l'hôte.

Le reverse proxy est le seul composant exposé sur les ports HTTP et HTTPS.

## Domaines

Avec un VPS dont l'adresse IPv4 est 203.0.113.50 :

    Frontend :          https://adyl.203.0.113.50.sslip.io
    API :               https://api.203.0.113.50.sslip.io
    Keycloak public :   https://auth.203.0.113.50.sslip.io
    Keycloak admin :    https://admin-auth.203.0.113.50.sslip.io

sslip.io résout automatiquement ces noms vers l'adresse IPv4 contenue dans le hostname.

## Sécurisation de Keycloak

Keycloak est séparé en deux surfaces :

### Surface publique

    https://auth.<IP>.sslip.io

Cette URL est utilisée par le frontend et le backend pour l'authentification OIDC.

Le realm master et l'interface d'administration sont bloqués sur ce hostname.

### Surface d'administration

    https://admin-auth.<IP>.sslip.io

Cette URL sert à :

    - la console Keycloak ;
    - l'Admin REST API ;
    - Terraform.

Nginx autorise uniquement l'adresse IP définie par :

    keycloak_admin_allowed_ip

dans :

    ansible/group_vars/production.yml

La valeur initiale est volontairement :

    CHANGE_ME_YOUR_IP

Il faut la remplacer par l'adresse IPv4 publique du PC depuis lequel Terraform et la console Keycloak seront utilisés.

Le playbook refuse de déployer tant que cette valeur n'a pas été remplacée.

Le challenge ACME de Let's Encrypt reste accessible publiquement sur le hostname d'administration afin de permettre l'émission et le renouvellement du certificat.

## Terraform Keycloak

Terraform est exécuté localement depuis le PC d'administration.

Il utilise :

    https://admin-auth.<IP>.sslip.io

pour accéder à l'Admin API.

Les applications utilisent séparément :

    https://auth.<IP>.sslip.io

pour les endpoints OIDC publics.

Le fichier :

    terraform/keycloak/terraform.tfvars

contient les valeurs locales et les secrets. Il est ignoré par Git.

Le fichier :

    terraform/keycloak/terraform.tfvars.example

sert de modèle.

Le state Terraform reste local dans :

    terraform/keycloak/terraform.tfstate

Le state doit rester privé car il peut contenir des informations sensibles.

## Keycloak

Terraform configure :

    master
    └── admin
        └── compte utilisé par Terraform

    adyl-creation
    ├── ADMIN
    ├── admin
    │   └── ADMIN
    ├── adyl-creation-api
    ├── adyl-creation-front
    └── adyl-creation-api client scope

Le mot de passe de l'administrateur du realm master est fourni au déploiement via GitHub Actions.

Le mot de passe de l'utilisateur applicatif est fourni localement à Terraform.

## TLS / Let's Encrypt

Le rôle Ansible tls :

    1. prépare le webroot ACME ;
    2. vérifie que le challenge est publiquement accessible ;
    3. demande le certificat Let's Encrypt si nécessaire ;
    4. installe le deploy hook Certbot ;
    5. recharge le reverse proxy lors d'un renouvellement.

Le certificat couvre :

    adyl.<IP>.sslip.io
    api.<IP>.sslip.io
    auth.<IP>.sslip.io
    admin-auth.<IP>.sslip.io

Il n'y a pas de dry-run automatique lors du renouvellement.

Pour tester l'émission d'un certificat sans consommer les limites de production de Let's Encrypt, utiliser l'option de staging prévue par la configuration.

Attention : détruire et recréer fréquemment une machine avec les mêmes domaines peut rencontrer les rate limits de Let's Encrypt. Cela vient du service Let's Encrypt et ne peut pas être garanti par Ansible.

## Déploiement

Le déploiement est déclenché manuellement depuis GitHub Actions.

La pipeline :

    1. installe Ansible ;
    2. installe les collections nécessaires ;
    3. configure l'accès SSH ;
    4. injecte les secrets GitHub dans des variables runtime temporaires ;
    5. exécute le playbook Ansible ;
    6. supprime le fichier temporaire contenant les secrets.

Ansible est la source de vérité pour la configuration du VPS.

## Premier déploiement

Avant de lancer la pipeline, remplacer dans :

    ansible/group_vars/production.yml

la valeur :

    keycloak_admin_allowed_ip: "CHANGE_ME_YOUR_IP"

par l'adresse IPv4 publique du PC d'administration.

Exemple :

    keycloak_admin_allowed_ip: "203.0.113.25"

Après le déploiement, vérifier :

    https://adyl.<IP>.sslip.io
    https://auth.<IP>.sslip.io
    https://admin-auth.<IP>.sslip.io

Puis lancer Terraform depuis :

    terraform/keycloak

avec un terraform.tfvars configuré selon terraform.tfvars.example.

Le provider Terraform doit utiliser le hostname d'administration.

## Commandes Terraform

Depuis terraform/keycloak :

    terraform init
    terraform fmt
    terraform validate
    terraform plan
    terraform apply

## Commandes Docker utiles

Sur le VPS :

    cd /opt/adyl-creation/docker

    docker compose ps

    docker compose logs -f api

    docker compose logs -f keycloak

    docker compose down

Pour supprimer également les données persistantes :

    docker compose down -v

Cette dernière commande supprime les bases PostgreSQL et les autres volumes de la stack.

## Sécurité du VPS

Le rôle security :

    - désactive la connexion SSH root ;
    - désactive l'authentification SSH par mot de passe ;
    - autorise uniquement la clé SSH ;
    - limite les utilisateurs SSH au deploy_user ;
    - active UFW ;
    - n'autorise que SSH, HTTP et HTTPS ;
    - active fail2ban pour SSH.

Le rôle Docker installe Docker Engine et le plugin Docker Compose.

Le rôle common installe les dépendances système et prépare les répertoires de déploiement.

## Idempotence et reconstruction

Le serveur ne doit pas contenir de configuration manuelle nécessaire au fonctionnement de la stack.

Après destruction du VPS, le même code Ansible peut reconstruire :

    - les paquets système ;
    - Docker ;
    - les règles UFW ;
    - fail2ban ;
    - la configuration SSH ;
    - les répertoires ;
    - Nginx ;
    - PostgreSQL ;
    - Keycloak ;
    - les certificats TLS ;
    - la stack Docker.

Les données persistantes sont volontairement stockées dans des volumes Docker. Leur conservation dépend donc de la conservation du serveur ou d'une stratégie de sauvegarde externe.

## Images applicatives

Les images sont configurées dans :

    ansible/group_vars/production.yml

Exemple :

    ghcr.io/lyesdouki/adyl-creation-front:latest
    ghcr.io/lyesdouki/adyl-creation-api:latest

En production, il est recommandé d'utiliser des tags immuables ou des digests afin d'éviter qu'un redéploiement récupère une image différente sous le même tag.
