# ===============================================================================
# Archivo: databricks_catalog.tf
# Descripción: Estructura lógica del Unity Catalog. Crea el catálogo raíz y
# mapea los esquemas lógicos (bronze, silver, gold) hacia sus ubicaciones
# físicas en AWS S3.
# ===============================================================================

# Crea el catálogo principal que agrupará todos nuestros esquemas
resource "databricks_catalog" "spinbyoxxo" {
  provider       = databricks.workspace
  name           = "spinbyoxxo"
  comment        = "Catálogo principal para el Data Lake"
  properties = {
    env = var.environment
  }
}

# Define el esquema Bronze y lo vincula estrictamente a su External Location en S3
resource "databricks_schema" "bronze" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.spinbyoxxo.id
  name         = "bronze"
  comment      = "Datos crudos (Raw Data)"
  storage_root = databricks_external_location.bronze.url
  properties = {
    layer = "bronze"
  }
}

# Define el esquema Silver para las tablas Delta procesadas y limpias
resource "databricks_schema" "silver" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.spinbyoxxo.id
  name         = "silver"
  comment      = "Datos limpios y estandarizados (Processed Data)"
  storage_root = databricks_external_location.silver.url
  properties = {
    layer = "silver"
  }
}

# Define el esquema Gold para las tablas analíticas finales
resource "databricks_schema" "gold" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.spinbyoxxo.id
  name         = "gold"
  comment      = "Modelado dimensional para analítica y reportes"
  storage_root = databricks_external_location.gold.url
  properties = {
    layer = "gold"
  }
}

# Otorga permisos de administración total al usuario propietario
resource "databricks_grants" "spinbyoxxo_catalog" {
  provider = databricks.workspace
  catalog  = databricks_catalog.spinbyoxxo.name

  grant {
    principal  = "gdlopezcastillo@gmail.com"
    privileges = ["ALL_PRIVILEGES"]
  }
}
