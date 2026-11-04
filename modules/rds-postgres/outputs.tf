output "address" {
  description = "Hostname do RDS."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Porta do Postgres."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Nome do banco."
  value       = aws_db_instance.this.db_name
}

output "endpoint" {
  description = "Endpoint do RDS (<address>:<port>)."
  value       = aws_db_instance.this.endpoint
}

output "username" {
  description = "Usuario master do banco."
  value       = aws_db_instance.this.username
}

output "password" {
  description = "Senha do usuario master."
  value       = random_password.this.result
  sensitive   = true
}

output "secret_arn" {
  description = "ARN do secret <prefix>-db com {username, password, host, port, dbname, engine}."
  value       = aws_secretsmanager_secret.this.arn
}

output "security_group_id" {
  description = "Id do security group do RDS."
  value       = aws_security_group.this.id
}

# O Postgres 17 no RDS vem com rds.force_ssl = 1; sslmode=require deixa isso explicito
# sem exigir o bundle de CA no container.
output "jdbc_url" {
  description = "URL JDBC do banco (com sslmode=require)."
  value       = "jdbc:postgresql://${aws_db_instance.this.address}:${aws_db_instance.this.port}/${aws_db_instance.this.db_name}?sslmode=require"
}
