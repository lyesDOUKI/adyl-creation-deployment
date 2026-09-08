# =========================================================================
# KEYCLOAK CONNECTION
# =========================================================================

variable "keycloak_url" {
  description = "Base URL of the Keycloak server"
  type        = string

  validation {
    condition     = can(regex("^https://", var.keycloak_url))
    error_message = "keycloak_url must use HTTPS."
  }
}

variable "keycloak_username" {
  description = "Username used by Terraform to administer Keycloak"
  type        = string
  sensitive   = true
}

variable "keycloak_password" {
  description = "Password used by Terraform to administer Keycloak"
  type        = string
  sensitive   = true
}

variable "keycloak_client_id" {
  description = "Keycloak client ID used by Terraform"
  type        = string
  default     = "admin-cli"
}


# =========================================================================
# REALM
# =========================================================================

variable "keycloak_realm" {
  description = "Name of the application Keycloak realm"
  type        = string
  default     = "adyl-creation"
}


# =========================================================================
# APPLICATION
# =========================================================================

variable "frontend_url" {
  description = "Public URL of the frontend application"
  type        = string

  validation {
    condition     = can(regex("^https://", var.frontend_url))
    error_message = "frontend_url must use HTTPS."
  }
}


# =========================================================================
# ADMIN USER
# =========================================================================

variable "admin_username" {
  description = "Username of the application administrator"
  type        = string
}

variable "admin_password" {
  description = "Initial password of the application administrator"
  type        = string
  sensitive   = true
}

variable "admin_email" {
  description = "Email address of the application administrator"
  type        = string
}

variable "admin_first_name" {
  description = "First name of the application administrator"
  type        = string
  default     = "Admin"
}

variable "admin_last_name" {
  description = "Last name of the application administrator"
  type        = string
  default     = "Adyl Creation"
}