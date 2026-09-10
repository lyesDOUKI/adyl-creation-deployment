# =========================================================================
# REALM USER PROFILE
# =========================================================================
# Déclare les attributs du profil utilisateur (remplace intégralement la
# config existante côté Keycloak : les attributs par défaut doivent être
# redéclarés ici, sinon ils disparaissent de la console).
# =========================================================================

resource "keycloak_realm_user_profile" "adyl_creation" {
  realm_id = keycloak_realm.adyl_creation.id

  attribute {
    name         = "username"
    display_name = "$${username}"

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }
  }

  attribute {
    name         = "email"
    display_name = "$${email}"

    required_for_roles = ["user"]

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "email"
    }
  }

  attribute {
    name         = "firstName"
    display_name = "$${firstName}"

    required_for_roles = ["user"]

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }
  }

  attribute {
    name         = "lastName"
    display_name = "$${lastName}"

    required_for_roles = ["user"]

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }
  }

  # --- Attribut téléphone --------------------------------------------

  attribute {
    name         = "phone"
    display_name = "Téléphone"

    required_for_roles = ["user"]

    permissions {
      view = ["admin", "user"]
      edit = ["admin", "user"]
    }

    validator {
      name = "pattern"
      config = {
        pattern       = "^\\+?[0-9]{6,15}$"
        error-message = "Numéro de téléphone invalide"
      }
    }
  }

  depends_on = [
    keycloak_realm.adyl_creation
  ]
}