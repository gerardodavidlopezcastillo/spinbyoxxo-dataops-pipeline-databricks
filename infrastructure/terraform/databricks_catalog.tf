# Catálogo de Unity Catalog
resource "databricks_catalog" "spinbyoxxo" {
  provider       = databricks.workspace
  name           = "spinbyoxxo"
  comment        = "Catálogo principal para el Data Lake"
  properties = {
    env = var.environment
  }
}

# Esquema Bronze
resource "databricks_schema" "bronze" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.spinbyoxxo.id
  name         = "bronze"
  comment      = "Datos crudos (Raw Data)"
  properties = {
    layer = "bronze"
  }
}

# Esquema Silver
resource "databricks_schema" "silver" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.spinbyoxxo.id
  name         = "silver"
  comment      = "Datos limpios y estandarizados (Processed Data)"
  properties = {
    layer = "silver"
  }
}

# Esquema Gold
resource "databricks_schema" "gold" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.spinbyoxxo.id
  name         = "gold"
  comment      = "Modelado dimensional para analítica y reportes"
  properties = {
    layer = "gold"
  }
}

# Asignar permisos al usuario actual sobre el catálogo
resource "databricks_grants" "spinbyoxxo_catalog" {
  provider = databricks.workspace
  catalog  = databricks_catalog.spinbyoxxo.name

  grant {
    principal  = "gdlopezcastillo@gmail.com"
    privileges = ["ALL_PRIVILEGES"]
  }
}
