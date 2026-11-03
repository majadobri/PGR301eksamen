output "service_url" {
  description = "Offentlig URL til tjenesten"
  value       = aws_ecs_express_gateway_service.wishifai.ingress_paths[0].endpoint
}

output "s3_bucket" {
  description = "Navn på S3-bucketen for bilder"
  value       = aws_s3_bucket.images.bucket
}

output "task_role_arn" {
  description = "ARN til task-rollen"
  value       = aws_iam_role.task_role.arn
}
