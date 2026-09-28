# ===============================================================================
# Archivo: databricks_workspace.tf
# Descripción: Orquesta la creación final del entorno de Databricks (Workspace)
# uniendo la red, el rol cross-account y el almacenamiento interno.
# ===============================================================================

# Crea el bucket interno requerido por Databricks para guardar logs y artefactos del sistema
resource "aws_s3_bucket" "root_storage_bucket" {
  bucket = "${var.prefix}-databricks-root-bucket-${var.account_id}"

  tags = {
    Name        = "${var.prefix}-databricks-root-bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "root_storage_bucket" {
  bucket                  = aws_s3_bucket.root_storage_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "root_storage_bucket" {
  bucket = aws_s3_bucket.root_storage_bucket.id
  versioning_configuration {
    status = "Disabled"
  }
}

data "databricks_aws_bucket_policy" "this" {
  bucket = aws_s3_bucket.root_storage_bucket.bucket
}

resource "aws_s3_bucket_policy" "root_bucket_policy" {
  bucket     = aws_s3_bucket.root_storage_bucket.id
  policy     = data.databricks_aws_bucket_policy.this.json
  depends_on = [aws_s3_bucket_public_access_block.root_storage_bucket]
}

# Registra el bucket interno en la plataforma de Databricks
resource "databricks_mws_storage_configurations" "this" {
  provider                   = databricks.mws
  account_id                 = var.databricks_account_id
  bucket_name                = aws_s3_bucket.root_storage_bucket.bucket
  storage_configuration_name = "${var.prefix}-storage"
}

resource "databricks_mws_networks" "this" {
  provider           = databricks.mws
  account_id         = var.databricks_account_id
  network_name       = "${var.prefix}-network"
  security_group_ids = [aws_security_group.databricks_sg.id]
  subnet_ids         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  vpc_id             = aws_vpc.main.id
}

# Construye finalmente el Workspace integrando todos los recursos en AWS
resource "databricks_mws_workspaces" "this" {
  provider                   = databricks.mws
  account_id                 = var.databricks_account_id
  aws_region                 = var.region
  workspace_name             = "${var.prefix}-workspace"
  credentials_id             = databricks_mws_credentials.this.credentials_id
  storage_configuration_id   = databricks_mws_storage_configurations.this.storage_configuration_id
  network_id                 = databricks_mws_networks.this.network_id
  token {
    comment = "Terraform Token"
  }
}

provider "databricks" {
  alias = "workspace"
  host  = databricks_mws_workspaces.this.workspace_url
  token = databricks_mws_workspaces.this.token[0].token_value
}

data "databricks_user" "me" {
  provider  = databricks.mws
  user_name = "david.657@hotmail.es"
}

resource "databricks_mws_permission_assignment" "me_as_admin" {
  provider     = databricks.mws
  workspace_id = databricks_mws_workspaces.this.workspace_id
  principal_id = data.databricks_user.me.id
  permissions  = ["ADMIN"]
}
