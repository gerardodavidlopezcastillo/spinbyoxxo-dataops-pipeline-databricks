# Este archivo contiene la definicion de los roles de IAM y sus politicas
resource "aws_iam_role" "redshift_role" { # crea la identidad de seguridad que el cluster usara para interactuar con otros servicios
  name = "${var.prefix}-RedshiftRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17" # version estandar del lenguaje de politicas json de aws
    Statement = [
      {
        Action    = "sts:AssumeRole" # accion clave que permite a una entidad tomar prestadas las credenciales del rol
        Effect    = "Allow" # concede el acceso explicitamente
        Principal = { Service = "redshift.amazonaws.com" } # define que solo el servicio de redshift tiene confianza para asumir este rol
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "redshift_s3_access" { # vincula los permisos especificos al rol que acabamos de crear
  name       = "${var.prefix}-RedshiftS3FullAccess"
  roles      = [aws_iam_role.redshift_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess" # politica administrada por aws que otorga control total sobre buckets s3 necesario para copy y unload
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.prefix}-LambdaExecutionRole" # identidad para que la funcion lambda pueda ejecutarse de forma segura

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_basic_execution" { # asocia permisos minimos necesarios para que la lambda funcione
  name       = "${var.prefix}-LambdaBasicExecutionRole"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" # permite a la lambda escribir logs en cloudwatch para monitoreo y depuracion
}

resource "aws_iam_policy_attachment" "lambda_redshift_access" { # conecta la lambda con redshift
  name       = "${var.prefix}-LambdaRedshiftDataAccess"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftDataFullAccess" # permite a la lambda ejecutar sql en el cluster usando la data api sin gestionar conexiones jdbc
}

resource "aws_iam_role_policy" "redshift_spectrum_policy" { # politica inline para dar superpoderes de lectura a redshift
  role = aws_iam_role.redshift_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow", # concede permiso explicito
        Action = [
          "s3:GetObject", # permite leer el contenido de los archivos parquet o csv
          "s3:ListBucket" # permite ver que archivos existen dentro del bucket
        ],
        Resource = [ # restringe el acceso solo a nuestros buckets de datos para mantener el principio de menor privilegio
          "arn:aws:s3:::${var.raw_bucket}",
          "arn:aws:s3:::${var.raw_bucket}/*",
          "arn:aws:s3:::${var.processed_bucket}",
          "arn:aws:s3:::${var.processed_bucket}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [ # permisos para que redshift entienda la estructura de los datos usando glue
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions"
        ],
        Resource = "*" # necesario para poder consultar cualquier tabla definida en el catalogo de datos
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_execution_role" { # rol de infraestructura que usa el agente de ecs para bajar la imagen y levantar el contenedor
  name = "${var.prefix}-ECSTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole" # permite tomar prestadas las credenciales temporalmente
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" } # autoriza al servicio de ecs a usar este rol
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_task_execution_policy" { # vincula los permisos necesarios para el arranque
  name       = "${var.prefix}-ECSTaskExecutionPolicy"
  roles      = [aws_iam_role.ecs_task_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" # politica oficial que permite pull de ecr y logs a cloudwatch
}

#

resource "aws_iam_role" "ecs_task_role" { # rol de aplicacion que usara tu script de python para tener permisos sobre s3 o redshift una vez este corriendo
  name = "${var.prefix}-ECSTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole" # operacion estandar para asumir identidad
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" } # el contenedor asume este rol al iniciar
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_s3_policy" { # define permisos personalizados s3 similar a lo que hicimos con redshift pero para que la app python pueda leer y escribir
  name        = "${var.prefix}-ECSS3Access" # nombre unico para identificar esta politica de acceso
  description = "Allow ECS task to access S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [ # operaciones permitidas: leer, escribir, borrar y listar archivos
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [ # limita el acceso estrictamente a los buckets del proyecto (raw y processed) por seguridad
          "arn:aws:s3:::${var.raw_bucket}",
          "arn:aws:s3:::${var.raw_bucket}/*",
          "arn:aws:s3:::${var.processed_bucket}",
          "arn:aws:s3:::${var.processed_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_s3_attachment" { # vincula la politica que acabamos de crear al rol de la tarea de ecs
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_s3_policy.arn
}