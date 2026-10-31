variable "name_prefix" {
  type        = string
  description = "Prefixo dos recursos (ex.: mecanica-identity). Gera o RDS <prefix>-db e o secret <prefix>-db."
}

variable "db_name" {
  type        = string
  description = "Nome do banco criado na instancia."
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security groups com acesso a porta do Postgres (ex.: o SG dos nodes do EKS)."
}

variable "instance_class" {
  type        = string
  description = "Classe da instancia RDS."
  default     = "db.t3.micro"
}
