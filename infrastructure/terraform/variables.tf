# Definimos las variables que se utilizaran en la configuracion
variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  default     = "gdlopezcastillo-cbc"
}

variable "account_id" {
  description = "AWS Account ID"
  default     = "508186271604"
}

variable "environment" {
  description = "Environment tag"
  default     = "dev"
}

variable "prefix" {
  description = "Prefix for resource names"
  default     = "globaltask"
}

variable "redshift_username" {
  description = "Redshift master username"
  default     = "adminuser"
}

variable "redshift_password" {
}

variable "raw_bucket" {
  description = "S3 bucket for raw data"
  default     = "globaltask-datalake-bronze"
}

variable "processed_bucket" {
  description = "S3 bucket for processed data"
  default     = "globaltask-datalake-silver"
}

variable "athena_results_bucket" {
  description = "S3 bucket for Athena query results"
  default     = "globaltask-athena-results"
}

variable "ecs_cpu" {
  description = "CPU units for ECS task"
  default     = 512
}

variable "ecs_memory" {
  description = "Memory (MB) for ECS task"
  default     = 1024
}

variable "ecs_desired_count" {
  description = "Number of ECS tasks to run"
  default     = 0 # Dejar 0 tareas activas, ideal EventBridge
}

# variable "ecs_subnets" {
#   description = "Subnets for ECS tasks"
#   type        = list(string)
#   default = [
#     "subnet-00c52eee0b5226053", # cbc-vpc-subnet-private1-us-east-1a
#     "subnet-0eaffef0f194c1de9"  # cbc-vpc-subnet-public1-us-east-1a
#   ]
# }

# variable "ecs_subnets" {
#   default = ["subnet-0eaffef0f194c1de9"] # pública
# }

# variable "ecs_security_groups" {
#   description = "Security groups for ECS tasks"
#   type        = list(string)
#   default = [
#     "sg-05f6903584b955e85" # default
#   ]
# }
