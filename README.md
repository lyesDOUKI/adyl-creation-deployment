# Adyl Creation — Deployment

Repository d'orchestration Docker pour la stack **Adyl Creation** : reverse proxy, frontend, API, PostgreSQL et Keycloak.

Il ne contient **aucun code applicatif**.

## Architecture

```text
Internet / navigateur
        │
        ▼
reverse-proxy (nginx)
├── /       → frontend
├── /api/   → api
└── auth.*  → keycloak

        │
        ▼
┌─────────────────────────────────────┐
│               proxy                 │
│  Réseau public                      │
│  reverse-proxy, frontend, api,      │
│  keycloak                            │
└────────────────┬────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────┐
│                data                 │
│  Réseau interne                     │
│  api, postgres, keycloak,            │
│  keycloak-db                         │
└─────────────────────────────────────┘
```

### Isolation réseau

* **postgres** et **keycloak-db** sont uniquement connectés au réseau `data`.
* Le **frontend** et le **reverse-proxy** n'ont aucun accès direct aux bases de données.
* Le réseau `proxy` permet uniquement les communications nécessaires entre le reverse proxy et les services exposés.

## Prérequis

* Docker avec le plugin Compose
* Accès aux images privées :

```bash
docker login ghcr.io
```

* [mkcert](https://github.com/FiloSottile/mkcert) ou une CA locale pour générer les certificats SSL de développement


## Mise en route

### Configuration

Copier le fichier d'environnement :

```bash
cp .env.example .env
```

Puis renseigner dans `.env` :

* les domaines utilisés ;
* les versions des images ;
* les identifiants ;
* les paramètres de base de données ;
* les paramètres de healthcheck.

### Hosts locaux

Ajouter les domaines à `/etc/hosts` :

```text
127.0.0.1 adyl-creation.local
127.0.0.1 auth.adyl-creation.local
```

### Certificats TLS

Générer les certificats HTTPS avec `mkcert` et les placer dans :

```text
nginx/ssl/
```

Placer également la CA correspondante dans :

```text
certificates/rootCA.pem
```

Cette CA est utilisée pour configurer le **truststore Java de l'API**.

### Déploiement

```bash
./deploy.sh
```

## Commandes utiles

Vérifier l'état de la stack :

```bash
docker compose ps
```

Afficher les logs d'un service :

```bash
docker compose logs -f api
```

Arrêter la stack en conservant les données :

```bash
docker compose down
```

Arrêter la stack et supprimer les volumes :

```bash
docker compose down -v
```

> `docker compose down -v` supprime les volumes Docker associés à la stack et doit donc être utilisé uniquement pour un reset complet.

## URLs de test

**Frontend**

```text
https://adyl-creation.local/
```

**API**

```text
https://adyl-creation.local/api/products
```

**Keycloak**

```text
https://auth.adyl-creation.local/
```

## Configuration `.env`

| Variable            | Description                      |
| ------------------- | -------------------------------- |
| `HTTP_PORT`         | Port exposé par le reverse proxy |
| `APP_HOSTNAME`      | Domaine de l'application         |
| `KEYCLOAK_HOSTNAME` | Domaine de Keycloak              |
| `FRONTEND_IMAGE`    | Image frontend avec tag figé     |
| `API_IMAGE`         | Image API avec tag figé          |
| `POSTGRES_VERSION`  | Version de PostgreSQL            |
| `KEYCLOAK_VERSION`  | Version de Keycloak              |
| `POSTGRES_*`        | Configuration PostgreSQL         |
| `KEYCLOAK_*`        | Configuration Keycloak           |
| `*_HEALTHCHECK_*`   | Configuration des healthchecks   |

## Rollback

Les images utilisées sont versionnées avec des tags immuables.

Pour revenir à une version précédente, modifier simplement les tags dans `.env` :

```text
FRONTEND_IMAGE=...
API_IMAGE=...
```

Puis redéployer :

```bash
docker compose pull
docker compose up -d
```

## Sécurité

### Exposition PostgreSQL

Le port `5433` de PostgreSQL est temporairement exposé afin de permettre les connexions depuis un client local comme **DBeaver** ou **SQL Developer**.

Cette exposition est uniquement destinée au développement local.

**Le port doit impérativement être supprimé du Compose avant tout déploiement en production ou sur un environnement partagé.**

### Frontend en lecture seule

Le conteneur frontend s'exécute avec :

```yaml
read_only: true
```

Cela limite les possibilités d'écriture du conteneur en cas de compromission.

### Keycloak derrière le reverse proxy

Keycloak utilise :

```text
--proxy-headers=xforwarded
```

afin de prendre correctement en compte les en-têtes transmis par le reverse proxy et de générer les URLs HTTPS attendues.
