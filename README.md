# fiap-soat-mecanica-db

Módulo Terraform **`rds-postgres`** da **Fase 4** da Oficina Mecânica do Braia (Tech Challenge FIAP SOAT). Cada serviço com banco SQL (`identity`, `os`, `billing`) cria o próprio RDS chamando este módulo no seu `infra/`.

O módulo cria, todos com o nome `<name_prefix>-db`:
- o DB subnet group;
- o security group do RDS, com uma regra de ingress na porta do Postgres para cada SG permitido e nenhuma regra de egress;
- o secret no Secrets Manager com `{username, password, host, port, dbname, engine}`;
- a instância RDS Postgres 17 (`db.t3.micro`, gp3 criptografado, privada, single-AZ).

O módulo não declara `provider` nem `backend`: a região e as `default_tags` vêm de quem o consome.

## Uso

Exemplo do `infra/` do Identity. A VPC, as subnets e o SG dos nodes vêm dos parâmetros SSM publicados pelo `-k8s`:

```hcl
data "aws_ssm_parameter" "vpc_id" {
  name = "/mecanica/k8s/vpc-id"
}

data "aws_ssm_parameter" "subnet_ids" {
  name = "/mecanica/k8s/subnet-ids"
}

data "aws_ssm_parameter" "node_sg" {
  name = "/mecanica/k8s/node-security-group-id"
}

module "db" {
  source = "git::https://github.com/fiap-postech-soat-lf/fiap-soat-mecanica-db.git//modules/rds-postgres?ref=v1"

  name_prefix                = "mecanica-identity"
  db_name                    = "identity"
  vpc_id                     = data.aws_ssm_parameter.vpc_id.insecure_value
  subnet_ids                 = split(",", data.aws_ssm_parameter.subnet_ids.insecure_value)
  allowed_security_group_ids = [data.aws_ssm_parameter.node_sg.insecure_value]
}

output "app_config" {
  value = {
    SPRING_DATASOURCE_URL = module.db.jdbc_url
  }
}

output "app_secrets" {
  sensitive = true
  value = {
    SPRING_DATASOURCE_USERNAME = module.db.username
    SPRING_DATASOURCE_PASSWORD = module.db.password
  }
}
```

> Os ids em `allowed_security_group_ids` precisam ser conhecidos no `plan` (são as chaves do `for_each` das regras de ingress). Os data sources de SSM atendem a isso, mas o id de um SG criado no mesmo `apply` não.

## Variáveis

| Nome | Tipo | Default | Descrição |
|---|---|---|---|
| `name_prefix` | `string` | — | Prefixo dos recursos (`^[a-z][a-z0-9-]{2,40}$`). Gera RDS, subnet group, SG e secret `<prefix>-db` |
| `db_name` | `string` | — | Nome do banco criado na instância (`^[a-z][a-z0-9_]{0,62}$`) |
| `vpc_id` | `string` | — | VPC do security group do RDS (a mesma do EKS) |
| `subnet_ids` | `list(string)` | — | Subnets do DB subnet group (no mínimo 2, em AZs diferentes) |
| `allowed_security_group_ids` | `list(string)` | — | Security groups com acesso à porta do Postgres (no mínimo 1) |
| `instance_class` | `string` | `db.t3.micro` | Classe da instância RDS |
| `engine_version` | `string` | `"17"` | Versão do Postgres (só a major) |
| `allocated_storage` | `number` | `20` | Armazenamento em GB (mínimo do gp3: 20) |
| `username` | `string` | `"postgres"` | Usuário master |
| `port` | `number` | `5432` | Porta do Postgres |
| `tags` | `map(string)` | `{}` | Tags extras em todos os recursos |

## Outputs

| Nome | Descrição |
|---|---|
| `address` | Hostname do RDS |
| `port` | Porta do Postgres |
| `db_name` | Nome do banco |
| `endpoint` | `<address>:<port>` |
| `username` | Usuário master |
| `password` | Senha do usuário master (**sensitive**) |
| `secret_arn` | ARN do secret `<prefix>-db` |
| `security_group_id` | Id do SG do RDS |
| `jdbc_url` | `jdbc:postgresql://<address>:<port>/<db_name>?sslmode=require` |

O Postgres 17 no RDS vem com `rds.force_ssl = 1`. O `sslmode=require` da `jdbc_url` deixa isso explícito sem exigir o bundle de CA no container.

## Destrutibilidade

O ambiente é destruído e recriado a cada janela de trabalho. Por isso o módulo usa:
- `recovery_window_in_days = 0` no secret, para o nome não ficar reservado por 7 dias;
- `skip_final_snapshot = true`, `deletion_protection = false` e `backup_retention_period = 0` no RDS.

## Testes

`modules/rds-postgres/tests/rds_postgres.tftest.hcl` roda com `mock_provider` (sem credencial AWS):

```bash
terraform -chdir=modules/rds-postgres init -backend=false
terraform -chdir=modules/rds-postgres test
```

| `run` | Prova |
|---|---|
| `nomes_derivados_do_prefixo` | RDS, subnet group, SG e secret = `<prefix>-db`; formato da `jdbc_url` |
| `uma_regra_por_sg_permitido` | 2 SGs → 2 regras de ingress na 5432/tcp, nenhuma com CIDR |
| `banco_privado_e_criptografado` | RDS privado, criptografado, sem snapshot final; secret sem janela de recuperação |
| `rejeita_prefixo_invalido` | validação de `name_prefix` |
| `rejeita_lista_de_sg_vazia` | validação de `allowed_security_group_ids` |
| `rejeita_uma_subnet_so` | validação de `subnet_ids` |

## Versionamento

Os serviços consomem a tag móvel `v1`. Mudança compatível: nova `v1.x.y` e a `v1` movida para ela. Mudança incompatível: `v2`.

## CI

O `ci.yml` chama o reusable `terraform-ci.yml@v1` do [`fiap-soat-mecanica-k8s`](https://github.com/fiap-postech-soat-lf/fiap-soat-mecanica-k8s) (check `ci / terraform`: `fmt`, `init -backend=false`, `validate` e `test`).

## Origem

Adaptado do repositório `-db` da Fase 3 do grupo (usado só para consulta). Diferenças: nomes derivados de `name_prefix` (um RDS por serviço), uma regra de ingress por SG permitido, SG sem egress, gp3 criptografado, senha de 32 caracteres e outputs para o contrato infra → CD (`jdbc_url`, `username`, `password`).
