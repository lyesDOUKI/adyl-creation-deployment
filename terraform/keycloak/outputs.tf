# =========================================================================
# KEYCLOAK OUTPUTS
# =========================================================================

output "keycloak_realm" {
  description = "Keycloak application realm"
  value       = keycloak_realm.adyl_creation.realm
}

output "keycloak_api_client_id" {
  description = "Keycloak API client ID"
  value       = keycloak_openid_client.api.client_id
}

output "keycloak_frontend_client_id" {
  description = "Keycloak frontend client ID"
  value       = keycloak_openid_client.frontend.client_id
}

output "keycloak_admin_username" {
  description = "Keycloak application administrator username"
  value       = keycloak_user.admin.username
}

output "keycloak_issuer_url" {
  description = "OIDC issuer URL for the application realm"
  value       = "${var.keycloak_url}/realms/${keycloak_realm.adyl_creation.realm}"
}