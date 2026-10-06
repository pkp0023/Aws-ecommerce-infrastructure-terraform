provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "cloudfront_acm"
  region = var.cloudfront_acm_region

  default_tags {
    tags = local.common_tags
  }
}
