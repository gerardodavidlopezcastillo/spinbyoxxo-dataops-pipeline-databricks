# Se crea un bucket especifico en S3
resource "aws_s3_bucket" "raw_data" {
  bucket = var.raw_bucket

  tags = {
    Environment = var.environment
    Name        = "${var.prefix}-raw-data"
  }
}

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
