resource "aws_ecr_repository" "globaltask_data_pipeline" { # Define el repositorio en AWS ECR donde se almacenaran las imágenes Docker de nuestro pipeline.
  name                 = "globaltask-data-pipeline"
  image_tag_mutability = "MUTABLE" # Permite sobrescribir etiquetas (como 'latest') sin borrar la imagen anterior. Es ideal para entornos de desarrollo/pruebas continuas.

  image_scanning_configuration {
    scan_on_push = true # Activa un escaneo de seguridad automático al subir la imagen para detectar vulnerabilidades (CVEs) en las dependencias.
  }

  encryption_configuration {
    encryption_type = "AES256" # Cifra las imágenes en reposo usando el estándar AES-256 manejado por S3, cumpliendo con requisitos de seguridad y compliance.
  }

  tags = {
    Project     = "globaltask-data-pipeline"
    Environment = var.environment
  }
}