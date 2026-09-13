# =========================================================================
# KEYCLOAK CONNECTION
# =========================================================================

variable "keycloak_url" {
  description = "Keycloak administration URL used by Terraform"
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


variable "keycloak_public_url" {
  description = "Public Keycloak URL used by applications and OIDC clients"
  type        = string

  validation {
    condition     = can(regex("^https://", var.keycloak_public_url))
    error_message = "keycloak_public_url must use HTTPS."
  }
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

variable "scalar_url" {
  description = "Public URL of the scalar application"
  type        = string

  validation {
    condition     = can(regex("^https://", var.scalar_url))
    error_message = "scalar_url must use HTTPS."
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

# =========================================================================
# SMTP (EMAIL)
# =========================================================================

variable "smtp_host" {
  description = "SMTP server hostname used by Keycloak to send emails"
  type        = string
}

variable "smtp_port" {
  description = "SMTP server port (e.g. 587 for STARTTLS, 465 for SSL, 25 for plain)"
  type        = string
  default     = "587"
}

variable "smtp_from" {
  description = "Email address used as the sender for realm emails"
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.smtp_from))
    error_message = "smtp_from must be a valid email address."
  }
}

variable "smtp_from_display_name" {
  description = "Display name used alongside the sender email address"
  type        = string
  default     = "Adyl Creation"
}

variable "smtp_reply_to" {
  description = "Reply-To email address for realm emails"
  type        = string
  default     = ""
}

variable "smtp_ssl" {
  description = "Whether to use SSL when connecting to the SMTP server (port 465 typically)"
  type        = bool
  default     = false
}

variable "smtp_starttls" {
  description = "Whether to use STARTTLS when connecting to the SMTP server (port 587 typically)"
  type        = bool
  default     = true
}

variable "smtp_auth_enabled" {
  description = "Whether the SMTP server requires authentication"
  type        = bool
  default     = true
}

variable "smtp_username" {
  description = "Username used to authenticate against the SMTP server"
  type        = string
  default     = ""
  sensitive   = true
}

variable "smtp_password" {
  description = "Password used to authenticate against the SMTP server"
  type        = string
  default     = ""
  sensitive   = true
}