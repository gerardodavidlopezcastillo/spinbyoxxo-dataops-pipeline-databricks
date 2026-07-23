terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # define el origen del plugin oficial de aws desde el registro de hashicorp
      version = "~> 4.0" # restringe la version a la 4.x permitiendo actualizaciones menores pero bloqueando la version 5 para evitar incompatibilidades
    }
  }
}

provider "aws" {
  region  = var.region
  profile = "gdlopezcastillo-cbc"
}
