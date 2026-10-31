# fiap-soat-mecanica-db

Módulo Terraform **`rds-postgres`** da **Fase 4** da Oficina Mecânica do Braia (Tech Challenge FIAP SOAT). Cada serviço com banco SQL (`identity`, `os`, `billing`) cria o próprio RDS chamando este módulo no seu `infra/`.

> 🚧 Em construção (fase F1). Na F1 o módulo só declara as variáveis. O corpo (RDS, security group, secret) entra na F2.

## Uso

```hcl
module "db" {
  source = "git::https://github.com/fiap-postech-soat-lf/fiap-soat-mecanica-db.git//modules/rds-postgres?ref=v1"

  name_prefix                = "mecanica-identity"
  db_name                    = "identity"
  allowed_security_group_ids = [data.aws_ssm_parameter.eks_node_sg.value]
  # instance_class           = "db.t3.micro" (default)
}
```

## Variáveis

| Nome | Tipo | Default | Descrição |
|---|---|---|---|
| `name_prefix` | `string` | — | Prefixo dos recursos. Gera o RDS `<prefix>-db` e o secret `<prefix>-db` |
| `db_name` | `string` | — | Nome do banco criado na instância |
| `allowed_security_group_ids` | `list(string)` | — | Security groups com acesso à porta do Postgres |
| `instance_class` | `string` | `db.t3.micro` | Classe da instância RDS |

Outputs: *TODO (F2)*.

## Versionamento

Os serviços consomem a tag móvel `v1`. Mudança compatível: nova `v1.x.y` e a `v1` movida para ela. Mudança incompatível: `v2`.

## CI

O `ci.yml` chama o reusable `terraform-ci.yml@v1` do [`fiap-soat-mecanica-k8s`](https://github.com/fiap-postech-soat-lf/fiap-soat-mecanica-k8s) (check `ci / terraform`: `fmt`, `init -backend=false`, `validate` e `test`).

## Origem

Adaptado do repositório `-db` da Fase 3 do grupo (usado só para consulta).
