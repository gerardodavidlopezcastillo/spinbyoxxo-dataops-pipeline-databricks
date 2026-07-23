output "redshift_cluster_endpoint" {
  description = "Redshift cluster endpoint"
  value       = aws_redshift_cluster.globaltask_cluster.endpoint # punto de acceso host y puerto para conectar clientes sql o herramientas de bi
}

output "redshift_role_arn" {
  description = "Redshift IAM role ARN"
  value       = aws_iam_role.redshift_role.arn # arn necesario para asociar este rol al cluster y permitirle leer de s3
}

output "lambda_role_arn" {
  description = "Lambda IAM role ARN"
  value       = aws_iam_role.lambda_role.arn # identificador del rol usado por la lambda para permisos de ejecucion
}

output "raw_bucket_name" {
  value = aws_s3_bucket.raw_data.bucket # nombre util para configurar scripts de carga que suben data cruda
}

output "processed_bucket_name" {
  value = aws_s3_bucket.processed_data.bucket # bucket destino para verificar donde caen los archivos parquet generados
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.globaltask_data_pipeline.repository_url # url exacta que necesitas usar en el comando docker push
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.globaltask_data_pipeline.arn # identificador unico del repo para definir politicas de permisos
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.globaltask_cluster.name # referencia para buscar el cluster en la consola o usar aws cli
}

output "ecs_task_definition_arn" {
  description = "ECS Task Definition ARN"
  value       = aws_ecs_task_definition.globaltask_task.arn # arn completo con la version de la tarea que se esta ejecutando
}

output "ecs_service_name" {
  description = "ECS Service name"
  value       = aws_ecs_service.globaltask_service.name # identificador para forzar actualizaciones del servicio si cambias la imagen
}