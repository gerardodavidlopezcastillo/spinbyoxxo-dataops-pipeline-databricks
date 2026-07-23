resource "aws_redshift_subnet_group" "globaltask_subnet_group" {
  name        = "${var.prefix}-subnet-group"
  description = "Subnet group for GlobalTask Redshift cluster"
  # Apuntamos a las subredes creadas en network.tf
  subnet_ids = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name        = "${var.prefix}-redshift-subnet-group"
    Environment = var.environment
  }
}

resource "aws_redshift_cluster" "globaltask_cluster" { # aprovisiona el cluster en redshift
  cluster_identifier  = "${var.prefix}-cluster"
  database_name       = "${var.prefix}_db"
  master_username     = var.redshift_username
  master_password     = var.redshift_password
  node_type           = "ra3.large" # instancia moderna que permite escalar almacenamiento y computo de forma independiente
  cluster_type        = "single-node" # configuracion economica de un solo nodo suficiente para la prueba tecnica
  publicly_accessible = true # permite conectar clientes sql desde fuera de la vpc como dbeaver o workbench

  cluster_subnet_group_name = aws_redshift_subnet_group.globaltask_subnet_group.name # vincula el cluster a la configuracion de red creada arriba
  vpc_security_group_ids = [aws_security_group.main_sg.id] # VINCULAMOS EL SECURITY GROUP AQUI
  iam_roles = [
    aws_iam_role.redshift_role.arn # adjunta el rol necesario para ejecutar comandos copy y unload hacia s3
  ]

  tags = {
    Name        = "${var.prefix}-redshift-cluster"
    Environment = var.environment
  }
}