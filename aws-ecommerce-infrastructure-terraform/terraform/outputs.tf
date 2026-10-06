output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (host:port)"
  value       = aws_db_instance.main.endpoint
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = "${aws_elasticache_cluster.redis.cache_nodes[0].address}:${var.redis_port}"
}

output "route53_name_servers" {
  description = "Set these as the NS records at your domain registrar"
  value       = aws_route53_zone.main.name_servers
}

output "frontend_bucket_name" {
  description = "S3 bucket to upload the React build into"
  value       = aws_s3_bucket.frontend.id
}

output "cloudfront_distribution_id" {
  description = "Distribution ID (for cache invalidations)"
  value       = aws_cloudfront_distribution.main.id
}

output "kafka_bootstrap_brokers" {
  description = "MSK bootstrap brokers (plaintext)"
  value       = aws_msk_cluster.main.bootstrap_brokers
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding the DB credentials"
  value       = aws_secretsmanager_secret.db.arn
}

output "ecs_api_service_name" {
  description = "ECS service running the backend API"
  value       = aws_ecs_service.api.name
}

output "ecs_worker_service_name" {
  description = "ECS service running the Kafka worker"
  value       = aws_ecs_service.worker.name
}
