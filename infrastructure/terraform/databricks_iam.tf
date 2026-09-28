# ===============================================================================
# Archivo: databricks_iam.tf
# Descripción: Configura la confianza entre AWS y Databricks (Cross-Account).
# Contiene los Roles de IAM que permiten a Databricks crear máquinas virtuales
# EC2 (clústeres) en nuestra VPC de manera segura.
# ===============================================================================

# Genera la política de confianza que exige el External ID de Databricks para mayor seguridad
data "databricks_aws_assume_role_policy" "this" {
  external_id = var.databricks_account_id
}

# Crea el rol en AWS que Databricks asumirá remotamente
resource "aws_iam_role" "cross_account_role" {
  name               = "${var.prefix}-databricks-cross-account-role"
  assume_role_policy = data.databricks_aws_assume_role_policy.this.json
  tags = {
    Name        = "${var.prefix}-databricks-cross-account-role"
    Environment = var.environment
  }
}

# Descarga los permisos exactos que necesita Databricks para orquestar EC2, EBS y VPCs
data "databricks_aws_crossaccount_policy" "this" {
}

# Adjunta la política de permisos al rol Cross-Account
resource "aws_iam_role_policy" "this" {
  name   = "${var.prefix}-databricks-cross-account-policy"
  role   = aws_iam_role.cross_account_role.id
  policy = data.databricks_aws_crossaccount_policy.this.json
}

resource "time_sleep" "wait_for_iam" {
  depends_on      = [aws_iam_role_policy.this]
  create_duration = "15s"
}

resource "databricks_mws_credentials" "this" {
  provider         = databricks.mws
  role_arn         = aws_iam_role.cross_account_role.arn
  credentials_name = "${var.prefix}-creds"
  depends_on       = [time_sleep.wait_for_iam]
}

