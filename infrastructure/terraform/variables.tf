# ===============================================================================
# Archivo: variables.tf
# Descripción: Define todas las variables de configuración dinámicas utilizadas
# en los módulos de Terraform. Esto permite reutilizar el código en múltiples
# entornos (dev, staging, prod) simplemente inyectando un archivo .tfvars distinto.
# ===============================================================================

# Región de AWS donde se desplegarán todos los recursos de infraestructura
variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

# Perfil local de AWS CLI para autenticación durante el despliegue
variable "aws_profile" {
  description = "AWS CLI profile to use"
  default     = "gdlopezcastillo-cbc"
}

# ID de la cuenta de AWS destino (utilizado para políticas de IAM cross-account)
variable "account_id" {
  description = "AWS Account ID"
  default     = "508186271604"
}

# Etiqueta de entorno para organizar costos y recursos (ej. dev, prod)
variable "environment" {
  description = "Environment tag"
  default     = "dev"
}

variable "prefix" {
  description = "Prefix for resource names"
  default     = "spinbyoxxo"
}



# Nombre del bucket destinado a la capa Bronze (datos inmutables crudos)
variable "raw_bucket" {
  description = "S3 bucket for raw data"
  default     = "spinbyoxxo-datalake-bronze"
}

variable "processed_bucket" {
  description = "S3 bucket for processed data"
  default     = "spinbyoxxo-datalake-silver"
}

variable "athena_results_bucket" {
  description = "S3 bucket for Athena query results"
  default     = "spinbyoxxo-athena-results"
}





# Credenciales OAuth M2M para interactuar con la API de Databricks Account
variable "databricks_account_id" {
  description = "Databricks Account ID"
  type        = string
}

variable "databricks_client_id" {
  description = "Databricks Account Client ID"
  type        = string
}

variable "databricks_client_secret" {
  description = "Databricks Account Client Secret"
  type        = string
  sensitive   = true
}

variable "gold_bucket" {
  description = "S3 bucket for gold data"
  default     = "spinbyoxxo-datalake-gold"
}
