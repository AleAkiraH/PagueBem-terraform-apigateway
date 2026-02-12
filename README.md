# PagueBem — API Gateway

API Gateway HTTP v2 do projeto PagueBem.

## Configuração

- **Tipo:** HTTP API v2
- **Route:** `$default` (catch-all — roteamento feito no Lambda)
- **Stage:** `{env}` com auto_deploy
- **CORS:** Configurado
- **Logs:** CloudWatch com formato JSON estruturado

## Dependências

- **Lambda** — `function_name` e `invoke_arn` nos `terraform.tfvars`

## Deploy

```powershell
# Init (primeira vez ou troca de ambiente)
terraform init -backend-config="key=apigateway/dev/terraform.tfstate"

# Plan
terraform plan -var-file="dev/terraform.tfvars"

# Apply
terraform apply -var-file="dev/terraform.tfvars"
```

## Destroy

```powershell
terraform destroy -var-file="dev/terraform.tfvars"
```

## Outputs

| Output | Descrição |
|--------|-----------|
| `api_endpoint` | URL do endpoint da API |
| `api_id` | ID da API Gateway |
| `api_execution_arn` | Execution ARN da API |
| `stage_name` | Nome do stage |

> Copie `api_endpoint` para o `.env` do Frontend (`VITE_API_URL`).
