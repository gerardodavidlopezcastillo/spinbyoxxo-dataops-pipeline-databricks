resource "aws_ecs_cluster" "globaltask_cluster" {
  name = "${var.prefix}-cluster"
}

# Log group para ECS
resource "aws_cloudwatch_log_group" "globaltask" { # Crea un grupo de logs centralizado para monitorear la salida de los contenedores y depurar errores.
  name              = "/ecs/${var.prefix}"
  retention_in_days = 7 # Retiene los logs solo por 7 dias para optimizar costos de almacenamiento en AWS.
}

# Definición de la tarea ECS
resource "aws_ecs_task_definition" "globaltask_task" {
  family                   = "${var.prefix}-task"
  cpu                      = var.ecs_cpu
  memory                   = var.ecs_memory
  network_mode             = "awsvpc" # Obligatorio para Fargate; asigna una ENI (interfaz de red) dedicada a la tarea para mayor seguridad.
  requires_compatibilities = ["FARGATE"] # Especifica que usaremos el modelo Serverless (sin gestionar instancias EC2).
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn # Rol para que ECS baje la imagen
  task_role_arn            = aws_iam_role.ecs_task_role.arn # Rol para usar S3

  container_definitions = jsonencode([{ # Define la especificación del contenedor en formato JSON requerido por la API de ECS.
    name      = "${var.prefix}-container"
    image     = "${aws_ecr_repository.globaltask_data_pipeline.repository_url}:latest" # Referencia dinámica a la imagen 'latest' del ECR que creamos con Terraform.
    cpu       = var.ecs_cpu
    memory    = var.ecs_memory
    essential = true

    portMappings = [{ # Exposición de puertos para permitir la comunicación con el contenedor.
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp" # Protocolo de transporte estándar para la comunicación de red.
    }]

    logConfiguration = {
      logDriver = "awslogs" # Configura el driver para enviar stdout/stderr directamente a CloudWatch en lugar de guardar en disco local.
      options = {
        awslogs-group         = aws_cloudwatch_log_group.globaltask.name
        awslogs-region        = var.region # Región de AWS donde se enviarán los logs.
        awslogs-stream-prefix = "ecs" # Prefijo para organizar y filtrar los streams de logs dentro del grupo.
      }
    }
  }])
}

# Servicio ECS usando solo subred publica
resource "aws_ecs_service" "globaltask_service" { # Orquesta la ejecucion de la tarea y asegura que el numero deseado de copias este corriendo
  name            = "${var.prefix}-service"
  cluster         = aws_ecs_cluster.globaltask_cluster.id
  task_definition = aws_ecs_task_definition.globaltask_task.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_1.id] # Referencia dinámica a la subred pública
    security_groups  = [aws_security_group.main_sg.id] # Referencia dinámica al Security Group
    assign_public_ip = true # Necesario para que Fargate tenga salida a internet y pueda descargar la imagen de ECR al no usar NAT Gateway
  }

  depends_on = [ # Garantiza que los roles y politicas de IAM esten creados antes de iniciar el servicio para evitar errores de permisos
    aws_iam_role.ecs_task_execution_role,
    aws_iam_policy_attachment.ecs_task_execution_policy,
    aws_iam_role.ecs_task_role
  ]
}