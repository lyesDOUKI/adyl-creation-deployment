# =========================================================================
# ADMIN USER
# =========================================================================
# Creates the initial administrator account for the application realm.
# =========================================================================

resource "keycloak_user" "admin" {
  realm_id = keycloak_realm.adyl_creation.id

  username = var.admin_username
  enabled  = true

  email          = var.admin_email
  email_verified = true

  first_name = var.admin_first_name
  last_name  = var.admin_last_name

  initial_password {
    value     = var.admin_password
    temporary = false
  }

  depends_on = [
    keycloak_role.admin
  ]
}


# =========================================================================
# ADMIN ROLE ASSIGNMENT
# =========================================================================
# Assigns the realm-level ADMIN role to the administrator user.
# =========================================================================

resource "keycloak_user_roles" "admin" {
  realm_id = keycloak_realm.adyl_creation.id
  user_id  = keycloak_user.admin.id

  role_ids = [
    keycloak_role.admin.id
  ]

  exhaustive = false
}