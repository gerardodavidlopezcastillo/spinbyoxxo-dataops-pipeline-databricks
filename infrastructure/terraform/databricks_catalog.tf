resource "databricks_catalog" "spinbyoxxo" {
  provider       = databricks.workspace
  name           = "spinbyoxxo"
  force_destroy  = true
  comment        = "Catálogo principal para el Data Lake"
  storage_root   = "s3://${aws_s3_bucket.raw_data.id}/catalog"
  depends_on     = [databricks_external_location.bronze]
}

resource "databricks_schema" "bronze" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.spinbyoxxo.name
  name         = "bronze"
  force_destroy = true
  storage_root = "s3://${aws_s3_bucket.raw_data.id}/"
  properties = { layer = "bronze" }
}

resource "databricks_schema" "silver" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.spinbyoxxo.name
  name         = "silver"
  force_destroy = true
  storage_root = "s3://${aws_s3_bucket.processed_data.id}/"
  properties = { layer = "silver" }
}

resource "databricks_schema" "gold" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.spinbyoxxo.name
  name         = "gold"
  force_destroy = true
  storage_root = "s3://${aws_s3_bucket.gold_data.id}/"
  properties = { layer = "gold" }
}

resource "databricks_grants" "spinbyoxxo_catalog" {
  provider = databricks.workspace
  catalog  = databricks_catalog.spinbyoxxo.name
  grant {
    principal  = "david.657@hotmail.es"
    privileges = ["ALL_PRIVILEGES"]
  }
}
