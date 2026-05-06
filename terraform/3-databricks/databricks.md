# Databricks Workspace Setup

## Deployment

Copy `backend.conf.example` to `backend.conf` and fill in the values for your environment, then initialise Terraform:

```bash
cp backend.conf.example backend.conf
terraform init -backend-config=backend.conf
terraform apply -var="workspace_url=https://<workspace>.azuredatabricks.net"
```

`backend.conf` is excluded from version control via `.gitignore`.

This stage of the Terraform Pipeline is to govern the deployment of resources within Databricks itself. This includes things such as clusters, sql warehouses, workspace settings.

Depending on your setup, you may include Unity Catalog objects and permissions within this step, however I would suggest that they are separated out into their own projects (Unity is not tightly tied to an individual workspace.)

You could also use this to deploy Databricks Workflows and DLT. This is not really best governed by Terraform, and tools such as Databricks Asset Bundles (DABS) work better for application code.

## Cluster Policies and Instance Pools

### Instance Pool (`shared`)

A single shared `Standard_DS3_v2` SPOT-with-fallback pool capped at 10 nodes. Both cluster policies draw from this pool so pre-warmed VMs are shared between interactive and job clusters, reducing cold-start times and cost.

### Cluster Policies

| Policy | Workers | Intended Use |
|--------|---------|--------------|
| `single-node` | 0 (local mode) | Exploratory notebooks, light ETL, unit testing — no driver/executor split overhead |
| `standard` | 1–8 | Multi-node jobs and shared interactive clusters |

Both policies pin `spark_version` to the latest LTS release and enforce a 30-minute autotermination window (configurable between 10 and 120 minutes) so idle clusters shut down automatically.

The policy IDs and pool ID are exported as Terraform outputs for consumption by downstream stages (e.g. DABS bundle configuration).

### Prerequisites
This is the first step that includes the Databricks Provider. The Azure is kept in case there is a requirement to deploy storage accounts or similar for use by the workspace as an external location.

Before running this stage you will need to do the following:
- Link your workspace to an established Unity Catalog metastore for your environment
- Grant permissions to your account within the workspace

## Secret Scope (Azure Key Vault-backed)

`secret-scope.tf` provisions a Databricks secret scope backed by an Azure Key Vault, enabling notebooks and jobs to read secrets from the vault without embedding credentials in code.

The scope is created via Databricks' Azure Key Vault integration (`keyvault_metadata`), which means the vault's secrets are accessed directly — they are not copied into Databricks.

**Variables required:**

| Variable | Description |
|---|---|
| `key_vault_id` | Full Azure resource ID of the Key Vault (e.g. `/subscriptions/.../resourceGroups/.../providers/Microsoft.KeyVault/vaults/my-vault`) |
| `key_vault_uri` | Vault URI (e.g. `https://my-vault.vault.azure.net/`) |

**Prerequisites:** The Key Vault must pre-exist, and the workspace managed identity must be granted the **Key Vault Secrets User** role on the vault before Terraform can create the scope.
