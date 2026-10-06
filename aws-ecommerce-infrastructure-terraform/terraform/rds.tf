resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "${local.name_prefix}-db-subnets" }
}

resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-postgres"

  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = var.db_storage_type
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result
  port     = var.db_port

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  backup_retention_period         = var.db_backup_retention_days
  auto_minor_version_upgrade      = true
  copy_tags_to_snapshot           = true
  enabled_cloudwatch_logs_exports = ["postgresql"]
  deletion_protection             = var.db_deletion_protection
  skip_final_snapshot             = var.db_skip_final_snapshot
  final_snapshot_identifier       = var.db_skip_final_snapshot ? null : "${local.name_prefix}-postgres-final"

  tags = { Name = "${local.name_prefix}-postgres" }
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${local.name_prefix}/rds/credentials"
  description             = "RDS PostgreSQL credentials and connection URL"
  recovery_window_in_days = var.secret_recovery_window_days

  tags = { Name = "${local.name_prefix}-db-credentials" }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    host     = aws_db_instance.main.address
    port     = var.db_port
    dbname   = var.db_name
    url      = "postgresql://${var.db_username}:${random_password.db.result}@${aws_db_instance.main.address}:${var.db_port}/${var.db_name}"
  })
}
