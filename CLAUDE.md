# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This is a teaching-focused Terraform reference project that deploys an Azure Databricks workspace with **zero public network exposure**. The workspace is accessible only through a private P2S VPN tunnel, with all Databricks control-plane traffic flowing over Azure Private Link. Every stage is self-contained with its own documentation so the patterns can be applied to real customer engagements.

## Terraform Deployment

This project has no build system, linter, or test runner. All work is manual Terraform CLI commands, executed stage-by-stage in order:

```bash
# Stage 0 — Bootstrap (local state, run once)
cd terraform/0-structure && terraform init && terraform apply
# After apply: manually grant "Storage Blob Data Owner" on the new storage account

# Stage 1 — Networking
cd terraform/1-network && terraform init && terraform apply

# Stage 2 — Workspaces + Private Endpoints
cd terraform/2-workspace && terraform init && terraform apply

# Stage 3 — In-workspace resources (requires workspace URL)
cd terraform/3-databricks && terraform init
terraform apply -var="workspace_url=https://<workspace>.azuredatabricks.net"
```

## Architecture

The network is deliberately split into **three independent resource groups and VNets** to mirror real customer team ownership:

| Layer | VNet | Purpose |
|-------|------|---------|
| Gateway (`rg-dbx-ml-gateway`) | `10.10.0.0/16` | P2S VPN gateway + Private DNS Resolver for VPN clients |
| Transit (`rg-dbx-ml-transit`) | `10.11.0.0/16` | Front-end private endpoint + browser_authentication workspace |
| Data Plane (`rg-dbx-ml-dataplane`) | `10.12.0.0/16` | App workspace, cluster subnets, back-end private endpoint |

All three VNets are peered, but Azure VNet peering is non-transitive — traffic from the gateway to the data plane is routed *through* the transit VNet via User Defined Routes.

**DNS complexity**: There are two private DNS zones with the **same name** (`privatelink.azuredatabricks.net`) in different VNets. Transit resolves to the front-end private endpoint; data plane resolves to the back-end. The Private DNS Resolver in the gateway VNet proxies DNS queries from VPN clients to the correct zone.

**Workspace split**: Two workspaces are deployed:
- **App workspace** — Premium SKU, no public IP, data plane VNet injection, private endpoints for `databricks_ui_api` and `browser_authentication`
- **Auth workspace** — Minimal, exists solely to host the `browser_authentication` private endpoint in the transit VNet

## Stage Dependencies (Remote State)

Stages 1–3 read outputs from previous stages via `terraform_remote_state` data sources pointing to Azure Storage (`tfstateb563727617b12739`, container `tfstate`). The backend is authenticated with Entra ID (no storage keys). Stage 0 is the only stage using local state.

## Hard-Coded Values

The following are intentionally hard-coded in `providers.tf` and `vars.tf` (parameterization is a planned improvement):

- Subscription ID: `972bbe39-991c-4055-80b8-ab36598f89c3`
- Tenant ID: `6d2c78dd-1f85-4ccb-9ae3-cd5ea1cca361`
- Default location: `WestUS2`
- Terraform state storage account: `tfstateb563727617b12739`

## Stage-Specific Notes

- **Stage 3** requires Unity Catalog metastore to be attached to the app workspace before `terraform apply` will succeed — this is a manual step in the Databricks UI.
- VPN client setup requires manual XML editing to configure DNS suffixes and server IP after downloading the VPN profile from the Azure portal.
- The auth workspace in stage 2 has no Databricks provider configuration because it exists only as an Azure resource — it is never configured from within Databricks.
