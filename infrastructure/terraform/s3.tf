# ===============================================================================
# Archivo: s3.tf
# Descripción: Provisiona los buckets físicos de Amazon S3 que actuarán como
# las capas de almacenamiento del Data Lake (Medallion Architecture).
# ===============================================================================

# Capa Bronze: Almacena los datos crudos extraídos directamente por CDC
resource "aws_s3_bucket" "raw_data" {
  bucket = var.raw_bucket
  force_destroy = true

  tags = {
    Environment = var.environment
    Name        = "${var.prefix}-raw-data"
  }
}

# Capa Silver: Almacena los datos filtrados, tipificados y con PII enmascarada
resource "aws_s3_bucket" "processed_data" {
  bucket = var.processed_bucket

  tags = {
    Environment = var.environment
    Name        = "${var.prefix}-processed-data"
  }
}

resource "aws_s3_bucket" "athena_results" {
  bucket = var.athena_results_bucket

  tags = {
    Environment = var.environment
    Name        = "${var.prefix}-athena-results"
  }
}

# Capa Gold: Almacena los modelos dimensionales orientados a negocio (Star Schema)
resource "aws_s3_bucket" "gold_data" {
  bucket = var.gold_bucket

  tags = {
    Environment = var.environment
    Name        = "${var.prefix}-gold-data"
  }
}
