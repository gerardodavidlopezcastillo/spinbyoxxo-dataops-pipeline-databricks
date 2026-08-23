# ===============================================================================
# Archivo: databricks_storage.tf
# Descripción: Configura las Credenciales de Almacenamiento y las Ubicaciones
# Externas (External Locations) que permiten a Databricks leer/escribir en S3.
# ===============================================================================

resource "aws_iam_role" "uc_storage_role" {
  name               = "${var.prefix}-uc-storage-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL",
            "arn:aws:iam::${var.account_id}:role/${var.prefix}-uc-storage-role"
          ]
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.databricks_account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "uc_storage_policy" {
  name = "${var.prefix}-uc-storage-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.raw_data.arn,
          "${aws_s3_bucket.raw_data.arn}/*",
          aws_s3_bucket.processed_data.arn,
          "${aws_s3_bucket.processed_data.arn}/*",
          aws_s3_bucket.gold_data.arn,
          "${aws_s3_bucket.gold_data.arn}/*"
        ]
      },
      {
        Action = [
          "sts:AssumeRole"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:iam::${var.account_id}:role/${var.prefix}-uc-storage-role"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "uc_storage" {
  role       = aws_iam_role.uc_storage_role.name
  policy_arn = aws_iam_policy.uc_storage_policy.arn
}

resource "time_sleep" "wait_for_storage_iam" {
  depends_on      = [aws_iam_role_policy_attachment.uc_storage]
  create_duration = "20s"

  triggers = {
    policy_hash = aws_iam_role.uc_storage_role.assume_role_policy
  }
}

# Registra el ARN del rol IAM que Databricks usará para conectarse a los buckets S3
resource "databricks_storage_credential" "aws_s3" {
  provider = databricks.workspace
  name     = "${var.prefix}-aws-s3-cred-v3"
  aws_iam_role {
    role_arn = aws_iam_role.uc_storage_role.arn
  }
  force_destroy = true
  depends_on = [time_sleep.wait_for_storage_iam]

  lifecycle {
    create_before_destroy = true
  }
}

# Autoriza a Databricks para gestionar archivos específicamente en el bucket Bronze
resource "databricks_external_location" "bronze" {
  provider        = databricks.workspace
  name            = "bronze_location"
  url             = "s3://${aws_s3_bucket.raw_data.id}"
  credential_name = databricks_storage_credential.aws_s3.id
  comment         = "Ubicacion para datos Bronze"
  force_destroy   = true
  force_update    = true
}

# Autoriza a Databricks para gestionar archivos específicamente en el bucket Silver
resource "databricks_external_location" "silver" {
  provider        = databricks.workspace
  name            = "silver_location"
  url             = "s3://${aws_s3_bucket.processed_data.id}"
  credential_name = databricks_storage_credential.aws_s3.id
  comment         = "Ubicacion para datos Silver"
  force_destroy   = true
  force_update    = true
}

# Autoriza a Databricks para gestionar archivos específicamente en el bucket Gold
resource "databricks_external_location" "gold" {
  provider        = databricks.workspace
  name            = "gold_location"
  url             = "s3://${aws_s3_bucket.gold_data.id}"
  credential_name = databricks_storage_credential.aws_s3.id
  comment         = "Ubicacion para datos Gold"
  force_destroy   = true
  force_update    = true
}

resource "databricks_grants" "bronze_external_location" {
  provider = databricks.workspace
  external_location = databricks_external_location.bronze.id

  grant {
    principal  = "gdlopezcastillo@gmail.com"
    privileges = ["READ_FILES", "WRITE_FILES", "CREATE_EXTERNAL_TABLE"]
  }
}

resource "databricks_grants" "silver_external_location" {
  provider = databricks.workspace
  external_location = databricks_external_location.silver.id

  grant {
    principal  = "gdlopezcastillo@gmail.com"
    privileges = ["READ_FILES", "WRITE_FILES", "CREATE_EXTERNAL_TABLE"]
  }
}

resource "databricks_grants" "gold_external_location" {
  provider = databricks.workspace
  external_location = databricks_external_location.gold.id

  grant {
    principal  = "gdlopezcastillo@gmail.com"
    privileges = ["READ_FILES", "WRITE_FILES", "CREATE_EXTERNAL_TABLE"]
  }
}
