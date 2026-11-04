# Testes do modulo com providers mockados: nao precisa de credencial AWS.

mock_provider "aws" {}

mock_provider "random" {}

variables {
  name_prefix                = "mecanica-identity"
  db_name                    = "identity"
  vpc_id                     = "vpc-0123456789abcdef0"
  subnet_ids                 = ["subnet-aaaaaaaaaaaaaaaaa", "subnet-bbbbbbbbbbbbbbbbb"]
  allowed_security_group_ids = ["sg-0123456789abcdef0"]
}

run "nomes_derivados_do_prefixo" {
  command = apply

  assert {
    condition     = aws_db_instance.this.identifier == "mecanica-identity-db"
    error_message = "O identificador do RDS deve ser <prefix>-db."
  }

  assert {
    condition     = aws_db_subnet_group.this.name == "mecanica-identity-db"
    error_message = "O subnet group deve ser <prefix>-db."
  }

  assert {
    condition     = aws_security_group.this.name == "mecanica-identity-db"
    error_message = "O security group deve ser <prefix>-db."
  }

  assert {
    condition     = aws_secretsmanager_secret.this.name == "mecanica-identity-db"
    error_message = "O secret deve ser <prefix>-db."
  }

  assert {
    condition     = startswith(output.jdbc_url, "jdbc:postgresql://") && endswith(output.jdbc_url, ":5432/identity?sslmode=require")
    error_message = "A jdbc_url deve apontar para o banco com sslmode=require."
  }
}

run "uma_regra_por_sg_permitido" {
  command = apply

  variables {
    allowed_security_group_ids = ["sg-0123456789abcdef0", "sg-0fedcba9876543210"]
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 2
    error_message = "Deve existir uma regra de ingress por SG permitido."
  }

  assert {
    condition = alltrue([
      for r in aws_vpc_security_group_ingress_rule.this :
      r.from_port == 5432 && r.to_port == 5432 && r.ip_protocol == "tcp"
    ])
    error_message = "As regras de ingress devem liberar so a porta 5432/tcp."
  }

  assert {
    condition = sort([
      for r in aws_vpc_security_group_ingress_rule.this : r.referenced_security_group_id
    ]) == sort(var.allowed_security_group_ids)
    error_message = "Cada regra deve referenciar um dos SGs permitidos."
  }

  assert {
    condition = alltrue([
      for r in aws_vpc_security_group_ingress_rule.this : r.cidr_ipv4 == null
    ])
    error_message = "Nenhuma regra de ingress pode liberar um bloco CIDR."
  }
}

run "banco_privado_e_criptografado" {
  command = apply

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false
    error_message = "O RDS nao pode ser publico."
  }

  assert {
    condition     = aws_db_instance.this.storage_encrypted == true
    error_message = "O storage do RDS deve ser criptografado."
  }

  assert {
    condition     = aws_db_instance.this.skip_final_snapshot == true
    error_message = "O RDS deve pular o snapshot final (destroy a cada janela)."
  }

  assert {
    condition     = aws_secretsmanager_secret.this.recovery_window_in_days == 0
    error_message = "O secret deve ter recovery_window_in_days = 0 (destroy a cada janela)."
  }
}

run "rejeita_prefixo_invalido" {
  command = plan

  variables {
    name_prefix = "Mecanica_Identity"
  }

  expect_failures = [var.name_prefix]
}

run "rejeita_lista_de_sg_vazia" {
  command = plan

  variables {
    allowed_security_group_ids = []
  }

  expect_failures = [var.allowed_security_group_ids]
}

run "rejeita_uma_subnet_so" {
  command = plan

  variables {
    subnet_ids = ["subnet-aaaaaaaaaaaaaaaaa"]
  }

  expect_failures = [var.subnet_ids]
}
