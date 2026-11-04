# RDS Postgres de um servico: subnet group, security group, senha aleatoria, secret
# <name_prefix>-db no Secrets Manager e a instancia. Adaptado do -db da Fase 3 do grupo.
# O modulo nao declara provider nem backend. Tudo e destrutivel (destroy a cada janela).

locals {
  name = "${var.name_prefix}-db"
}

resource "aws_db_subnet_group" "this" {
  name       = local.name
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, { Name = local.name })
}

# Sem regra de egress: o RDS nao inicia conexoes.
resource "aws_security_group" "this" {
  name        = local.name
  description = "Acesso ao Postgres ${local.name}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = local.name })
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = var.port
  to_port                      = var.port
  description                  = "Postgres a partir de ${each.value}"

  tags = var.tags
}

# special = false evita os caracteres que o RDS recusa na senha master (/, @, " e espaco).
resource "random_password" "this" {
  length  = 32
  special = false
}

# recovery_window_in_days = 0: sem isso o nome fica reservado por 7 dias e o apply
# da janela seguinte falha.
resource "aws_secretsmanager_secret" "this" {
  name                    = local.name
  description             = "Credenciais do Postgres ${local.name}"
  recovery_window_in_days = 0

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    username = var.username
    password = random_password.this.result
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
    engine   = "postgres"
  })
}

resource "aws_db_instance" "this" {
  identifier     = local.name
  db_name        = var.db_name
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  username = var.username
  password = random_password.this.result
  port     = var.port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false
  multi_az               = false

  skip_final_snapshot          = true
  deletion_protection          = false
  backup_retention_period      = 0
  apply_immediately            = true
  performance_insights_enabled = false

  tags = merge(var.tags, { Name = local.name })
}
