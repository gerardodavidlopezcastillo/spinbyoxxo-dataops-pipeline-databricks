


output "raw_bucket_name" {
  value = aws_s3_bucket.raw_data.bucket # nombre util para configurar scripts de carga que suben data cruda
}

output "processed_bucket_name" {
  value = aws_s3_bucket.processed_data.bucket # bucket destino para verificar donde caen los archivos parquet generados
}






output "databricks_workspace_url" {
  description = "URL del Workspace de Databricks"
  value       = databricks_mws_workspaces.this.workspace_url
}