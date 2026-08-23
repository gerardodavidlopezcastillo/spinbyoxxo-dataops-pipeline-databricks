terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # define el origen del plugin oficial de aws desde el registro de hashicorp
      version = "~> 4.0" # restringe la version a la 4.x permitiendo actualizaciones menores pero bloqueando la version 5 para evitar incompatibilidades
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.50"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "gdlopezcastillo-cbc"
}

provider "databricks" {
  alias      = "mws"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
  client_id  = var.databricks_client_id
  client_secret = var.databricks_client_secret
}
