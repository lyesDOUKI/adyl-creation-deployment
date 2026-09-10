# =========================================================================
# KEYCLOAK REALM
# =========================================================================

resource "keycloak_realm" "adyl_creation" {
  realm   = var.keycloak_realm
  enabled = true

  # -----------------------------------------------------------------------
  # User registration
  # -----------------------------------------------------------------------

  registration_allowed = true

  # -----------------------------------------------------------------------
  # Internationalization
  # -----------------------------------------------------------------------

  internationalization {
    supported_locales = [
      "fr"
    ]

    default_locale = "fr"
  }
}


# =========================================================================
# REALM ROLES
# =========================================================================

resource "keycloak_role" "admin" {
  realm_id = keycloak_realm.adyl_creation.id
  name     = "ADMIN"

  description = "Administrator role for Adyl Creation"
}

resource "keycloak_role" "user" {
  realm_id = keycloak_realm.adyl_creation.id
  name     = "USER"

  description = "Default role for registered users"
}

resource "keycloak_default_roles" "adyl_creation" {
  realm_id = keycloak_realm.adyl_creation.id

  default_roles = [
    keycloak_role.user.name
  ]
}
# =========================================================================
# API CLIENT SCOPE
# =========================================================================
# This scope allows the API audience to be included in access tokens.
# =========================================================================

resource "keycloak_openid_client_scope" "api" {
  realm_id = keycloak_realm.adyl_creation.id

  name        = "adyl-creation-api"
  description = "Audience scope for the Adyl Creation API"

  include_in_token_scope = true
}


# =========================================================================
# API AUDIENCE MAPPER
# =========================================================================
# Adds adyl-creation-api to the token audience when the scope is used.
# =========================================================================

resource "keycloak_openid_audience_protocol_mapper" "api_audience" {
  realm_id        = keycloak_realm.adyl_creation.id
  client_scope_id = keycloak_openid_client_scope.api.id

  name = "adyl-creation-api-audience"

  included_client_audience = keycloak_openid_client.api.client_id
}


# =========================================================================
# API CLIENT
# =========================================================================

resource "keycloak_openid_client" "api" {
  realm_id = keycloak_realm.adyl_creation.id

  client_id = "adyl-creation-api"
  name      = "Adyl Creation API"

  enabled = true

  access_type = "CONFIDENTIAL"

  standard_flow_enabled         = false
  direct_access_grants_enabled = false
  implicit_flow_enabled         = false

  service_accounts_enabled = true
}


# =========================================================================
# FRONTEND CLIENT
# =========================================================================
# Public OIDC client used by the React frontend.
# Authorization Code + PKCE is used by the frontend.
# =========================================================================

resource "keycloak_openid_client" "frontend" {
  realm_id = keycloak_realm.adyl_creation.id

  client_id = "adyl-creation-front"
  name      = "Adyl Creation Frontend"

  enabled = true

  access_type = "PUBLIC"

  standard_flow_enabled         = true
  direct_access_grants_enabled = false
  implicit_flow_enabled        = false

  valid_redirect_uris = [
    "${var.frontend_url}/*",
    "${var.scalar_url}/*"
  ]

  web_origins = [
    var.frontend_url,
    var.scalar_url
  ]
}


# =========================================================================
# FRONTEND DEFAULT CLIENT SCOPES
# =========================================================================
# These scopes are automatically requested for the frontend client.
# =========================================================================

resource "keycloak_openid_client_default_scopes" "frontend" {
  realm_id  = keycloak_realm.adyl_creation.id
  client_id = keycloak_openid_client.frontend.id

  default_scopes = [
    "basic",
    "openid",
    "profile",
    "email",
    "roles",
    "web-origins",
    keycloak_openid_client_scope.api.name
  ]
}

# =========================================================================
# API PHONE ATTRIBUTE MAPPER
# =========================================================================
# Exposes the user's phone attribute in the access token as "phone".
# =========================================================================

resource "keycloak_generic_protocol_mapper" "api_phone" {
  realm_id        = keycloak_realm.adyl_creation.id
  client_scope_id = keycloak_openid_client_scope.api.id

  name            = "phone"
  protocol        = "openid-connect"
  protocol_mapper = "oidc-usermodel-attribute-mapper"

  config = {
    "user.attribute"      = "phone"
    "claim.name"          = "phone"
    "jsonType.label"      = "String"
    "access.token.claim"  = "true"
    "id.token.claim"      = "false"
    "userinfo.token.claim" = "false"
  }
}