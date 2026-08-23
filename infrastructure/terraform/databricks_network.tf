# Elastic IP para el NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true

  tags = {
    Name        = "${var.prefix}-nat-eip"
    Environment = var.environment
  }
}

# NAT Gateway (ubicado en la subred pública 1)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name        = "${var.prefix}-nat-gw"
    Environment = var.environment
  }
}

# Subred Privada 1 (us-east-1a)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name        = "${var.prefix}-subnet-private-1"
    Environment = var.environment
  }
}

# Subred Privada 2 (us-east-1b)
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name        = "${var.prefix}-subnet-private-2"
    Environment = var.environment
  }
}

# Tabla de enrutamiento para las subredes privadas (salida vía NAT)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name        = "${var.prefix}-private-rt"
    Environment = var.environment
  }
}

# Asociaciones de las subredes privadas con la tabla de enrutamiento privada
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# Security Group para Databricks
resource "aws_security_group" "databricks_sg" {
  name        = "${var.prefix}-databricks-sg"
  description = "Security group for Databricks workspace"
  vpc_id      = aws_vpc.main.id

  # Reglas recomendadas por Databricks: todo el tráfico permitido entre nodos del mismo SG
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # Salida permitida a cualquier destino (requerido para comunicación con control plane)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.prefix}-databricks-sg"
    Environment = var.environment
  }
}
