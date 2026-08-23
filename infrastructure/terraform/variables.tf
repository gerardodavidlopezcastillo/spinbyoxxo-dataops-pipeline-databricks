# Definimos las variables que se utilizaran en la configuracion
variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  default     = "gdlopezcastillo-cbc"
}

variable "account_id" {
  description = "AWS Account ID"
  default     = "508186271604"
}

variable "environment" {
  description = "Environment tag"
  default     = "dev"
}

variable "prefix" {
  description = "Prefix for resource names"
  default     = "spinbyoxxo"
}



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





# Databricks Variables
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
