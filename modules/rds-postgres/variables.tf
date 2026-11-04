variable "name_prefix" {
  type        = string
  description = "Prefixo dos recursos (ex.: mecanica-identity). Gera o RDS <prefix>-db e o secret <prefix>-db."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,40}$", var.name_prefix))
    error_message = "name_prefix deve comecar com letra minuscula e ter de 3 a 41 caracteres [a-z0-9-]."
  }
}

variable "db_name" {
  type        = string
  description = "Nome do banco criado na instancia."

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.db_name))
    error_message = "db_name deve comecar com letra minuscula e ter ate 63 caracteres [a-z0-9_]."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC do security group do RDS (a mesma do EKS)."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets do DB subnet group (no minimo 2, em AZs diferentes)."

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids precisa de pelo menos 2 subnets (o DB subnet group exige 2 AZs)."
  }
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security groups com acesso a porta do Postgres (ex.: o SG dos nodes do EKS)."

  validation {
    condition     = length(var.allowed_security_group_ids) >= 1
    error_message = "allowed_security_group_ids precisa de pelo menos 1 security group."
  }
}

variable "instance_class" {
  type        = string
  description = "Classe da instancia RDS."
  default     = "db.t3.micro"
}

variable "engine_version" {
  type        = string
  description = "Versao do Postgres (so a major: o RDS escolhe a minor padrao)."
  default     = "17"
}

variable "allocated_storage" {
  type        = number
  description = "Armazenamento alocado, em GB (minimo do gp3: 20)."
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage deve ser de pelo menos 20 GB (minimo do gp3)."
  }
}

variable "username" {
  type        = string
  description = "Usuario master do banco."
  default     = "postgres"
}

variable "port" {
  type        = number
  description = "Porta do Postgres."
  default     = 5432
}

variable "tags" {
  type        = map(string)
  description = "Tags extras aplicadas a todos os recursos (alem das default_tags do provider de quem consome)."
  default     = {}
}
