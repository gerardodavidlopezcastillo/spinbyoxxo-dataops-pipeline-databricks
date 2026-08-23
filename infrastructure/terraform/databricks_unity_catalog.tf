# S3 Bucket para Unity Catalog Metastore
resource "aws_s3_bucket" "metastore" {
  bucket = "${var.prefix}-databricks-metastore-${var.account_id}"

  tags = {
    Name        = "${var.prefix}-databricks-metastore"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "metastore" {
  bucket                  = aws_s3_bucket.metastore.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "metastore" {
  bucket = aws_s3_bucket.metastore.id
  versioning_configuration {
    status = "Disabled"
  }
}

# IAM Role for Unity Catalog
data "aws_iam_policy_document" "passrole_for_uc" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::414351767826:role/unity-catalog-prod-UCMasterRole-14S5ZJVKOTYTL"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.databricks_account_id]
    }
  }
}

resource "aws_iam_policy" "unity_metastore" {
  name = "${var.prefix}-unity-catalog-metastore-access-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${var.prefix}-databricks-unity-metastore"
    Statement = [
      {
        "Action" : [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource" : [
          aws_s3_bucket.metastore.arn,
          "${aws_s3_bucket.metastore.arn}/*"
        ],
        "Effect" : "Allow"
      },
      {
        "Action" : [
          "sts:AssumeRole"
        ],
        "Resource" : [
          "arn:aws:iam::${var.account_id}:role/${var.prefix}-uc-access"
        ],
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role" "metastore_data_access" {
  name               = "${var.prefix}-uc-access"
  assume_role_policy = data.aws_iam_policy_document.passrole_for_uc.json
  managed_policy_arns = [aws_iam_policy.unity_metastore.arn]
  tags = {
    Name        = "${var.prefix}-uc-access"
    Environment = var.environment
  }
}

# Configuración del Metastore en Databricks Account
resource "databricks_metastore" "this" {
  provider      = databricks.mws
  name          = "${var.prefix}-metastore"
  storage_root  = "s3://${aws_s3_bucket.metastore.id}/metastore"
  force_destroy = true
  region        = var.region
}

resource "databricks_metastore_data_access" "this" {
  provider     = databricks.mws
  metastore_id = databricks_metastore.this.id
  name         = aws_iam_role.metastore_data_access.name
  aws_iam_role {
    role_arn = aws_iam_role.metastore_data_access.arn
  }
  is_default = true
}

resource "databricks_metastore_assignment" "this" {
  provider             = databricks.workspace
  workspace_id         = databricks_mws_workspaces.this.workspace_id
  metastore_id         = databricks_metastore.this.id
  default_catalog_name = "spinbyoxxo_workspace"
}
