data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}


data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = local.cloudfront_prefix_list_name
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.additional_tags
  )

  azs       = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))
  nat_count = var.single_nat_gateway ? 1 : length(var.public_subnet_cidrs)

  cloudfront_prefix_list_name = "com.amazonaws.global.cloudfront.origin-facing"

  api_fqdn           = "${var.api_subdomain}.${var.domain_name}"
  cloudfront_aliases = [var.domain_name, "${var.www_subdomain}.${var.domain_name}"]

  s3_origin_id  = "s3-frontend"
  alb_origin_id = "alb-api"
}
