
variable "aws_region" {
  description = "AWS region for all regional resources"
  type        = string
  default     = "ap-south-1"
}

variable "cloudfront_acm_region" {
  description = "Region where the ACM certificate used by CloudFront must be created (AWS requires us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name, used in resource names and the Project tag"
  type        = string
  default     = "shopyyy"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "additional_tags" {
  description = "Extra tags merged into the default tags of every resource"
  type        = map(string)
  default     = {}
}


variable "domain_name" {
  description = "Root domain served by the application"
  type        = string
  # Set this to a domain you control in terraform.tfvars.
}

variable "api_subdomain" {
  description = "Subdomain pointing to the ALB; CloudFront uses it as the API origin so TLS to the origin validates"
  type        = string
  default     = "api"
}


variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDRs of the public subnets (one per AZ, at least 2)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs of the private subnets (one per AZ, same count as public)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "Provide at least 2 private subnets so workloads span 2 AZs."
  }
}

variable "single_nat_gateway" {
  description = "true = one shared NAT Gateway (cheaper); false = one NAT Gateway per AZ (highly available)"
  type        = bool
  default     = false
}


variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "frontend_bucket_force_destroy" {
  description = "Allow terraform destroy to delete the frontend bucket even if it has objects"
  type        = bool
  default     = true
}

variable "origin_verify_header_name" {
  description = "Secret header CloudFront adds so the ALB only serves requests that came through CloudFront"
  type        = string
  default     = "X-Origin-Verify"
}


variable "alb_ssl_policy" {
  description = "TLS policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "health_check_path" {
  description = "Target group health check path"
  type        = string
  default     = "/api/health"
}


variable "container_name" {
  description = "Name of the backend container"
  type        = string
  default     = "api"
}

variable "container_image" {
  description = "Backend container image (placeholder by default)"
  type        = string
  default     = "hashicorp/http-echo:1.0"
}

variable "container_command" {
  description = "Command override for the placeholder image so it listens on container_port. Set to [] for your real image."
  type        = list(string)
  default     = ["-listen=:3000", "-text=ok"]
}

variable "container_port" {
  description = "Port the backend listens on"
  type        = number
  default     = 3000
}

variable "container_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 512
}

variable "container_memory" {
  description = "Fargate task memory (MiB)"
  type        = number
  default     = 1024
}

variable "ecs_desired_count" {
  description = "Number of running tasks"
  type        = number
  default     = 2
}

variable "container_environment" {
  description = "Extra plain environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch log retention"
  type        = number
  default     = 14
}


variable "db_engine_version" {
  description = "PostgreSQL engine version (major-only lets RDS pick the current minor)"
  type        = string
  default     = "17"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Initial storage in GiB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Storage autoscaling ceiling in GiB"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "shopyyy"
}

variable "db_username" {
  description = "Master username"
  type        = string
  default     = "shopyyy_admin"
}

variable "db_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

variable "db_backup_retention_days" {
  description = "Automated backup retention"
  type        = number
  default     = 7
}

variable "db_skip_final_snapshot" {
  description = "Skip the final snapshot on destroy (true is fine for dev, use false in prod)"
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Enable RDS deletion protection"
  type        = bool
  default     = false
}

variable "secret_recovery_window_days" {
  description = "Secrets Manager recovery window (0 = delete immediately, handy for dev)"
  type        = number
  default     = 0
}


variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "redis_parameter_group_name" {
  description = "Redis parameter group matching the engine version"
  type        = string
  default     = "default.redis7"
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}


variable "kafka_version" {
  description = "Apache Kafka version"
  type        = string
  default     = "3.6.0"
}

variable "kafka_broker_count" {
  description = "Number of brokers (must be a multiple of the AZ count)"
  type        = number
  default     = 2
}

variable "kafka_instance_type" {
  description = "Broker instance type"
  type        = string
  default     = "kafka.t3.small"
}

variable "kafka_ebs_volume_size" {
  description = "EBS volume per broker (GiB)"
  type        = number
  default     = 20
}

variable "kafka_port" {
  description = "Kafka client port (9092 = plaintext listener)"
  type        = number
  default     = 9092
}

variable "kafka_client_broker_encryption" {
  description = "Client-broker encryption mode. PLAINTEXT exposes port 9092 inside the VPC; use TLS (port 9094) for production."
  type        = string
  default     = "PLAINTEXT"
}


variable "https_port" {
  description = "HTTPS port used by the ALB listener, ALB security group and CloudFront origin"
  type        = number
  default     = 443
}

variable "http_port" {
  description = "HTTP port (only referenced in the CloudFront custom origin config; the origin policy is https-only)"
  type        = number
  default     = 80
}

variable "www_subdomain" {
  description = "Subdomain that also serves the site through CloudFront"
  type        = string
  default     = "www"
}

variable "api_path_pattern" {
  description = "Path pattern CloudFront (and the ALB listener rule) route to the backend API"
  type        = string
  default     = "/api/*"
}

variable "frontend_index_document" {
  description = "Index document of the React app (default root object and SPA rewrite target)"
  type        = string
  default     = "index.html"
}

variable "cloudfront_min_protocol_version" {
  description = "Minimum TLS version CloudFront accepts from viewers"
  type        = string
  default     = "TLSv1.2_2021"
}

variable "acm_validation_ttl" {
  description = "TTL (seconds) of the ACM DNS validation records"
  type        = number
  default     = 60
}

variable "tg_health_check_interval" {
  description = "Target group health check interval (seconds)"
  type        = number
  default     = 30
}

variable "tg_health_check_timeout" {
  description = "Target group health check timeout (seconds)"
  type        = number
  default     = 5
}

variable "tg_healthy_threshold" {
  description = "Consecutive successes before a target is healthy"
  type        = number
  default     = 2
}

variable "tg_unhealthy_threshold" {
  description = "Consecutive failures before a target is unhealthy"
  type        = number
  default     = 3
}

variable "tg_health_check_matcher" {
  description = "HTTP codes treated as healthy"
  type        = string
  default     = "200-399"
}

variable "tg_deregistration_delay" {
  description = "Seconds the ALB waits before deregistering a draining target"
  type        = number
  default     = 30
}

variable "ecs_health_check_grace_period" {
  description = "Seconds ECS ignores ALB health checks after a task starts"
  type        = number
  default     = 60
}

variable "container_insights" {
  description = "ECS Container Insights setting (enabled or disabled)"
  type        = string
  default     = "enabled"
}

variable "worker_container_name" {
  description = "Name of the Kafka worker container"
  type        = string
  default     = "worker"
}

variable "worker_container_image" {
  description = "Kafka worker container image (placeholder by default)"
  type        = string
  default     = "hashicorp/http-echo:1.0"
}

variable "worker_container_command" {
  description = "Command override for the placeholder worker image. Set to [] for your real worker image."
  type        = list(string)
  default     = ["-listen=:3001", "-text=worker"]
}

variable "worker_cpu" {
  description = "Fargate CPU units for the worker task"
  type        = number
  default     = 256
}

variable "worker_memory" {
  description = "Fargate memory (MiB) for the worker task"
  type        = number
  default     = 512
}

variable "worker_desired_count" {
  description = "Number of running worker tasks (one per AZ by default)"
  type        = number
  default     = 2
}

variable "db_engine" {
  description = "RDS engine"
  type        = string
  default     = "postgres"
}

variable "db_storage_type" {
  description = "RDS storage type"
  type        = string
  default     = "gp3"
}

variable "redis_engine" {
  description = "ElastiCache engine"
  type        = string
  default     = "redis"
}

variable "redis_num_cache_nodes" {
  description = "Number of Redis nodes (single node is enough for this assessment)"
  type        = number
  default     = 1
}
