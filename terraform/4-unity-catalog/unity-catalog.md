# Unity Catalog Stage

## Overview

This stage provisions Unity Catalog resources within the app workspace deployed in stage 2. It handles the metastore assignment and any in-workspace Unity Catalog objects (catalogs, schemas, storage credentials).

## Prerequisites

Before running this stage you must complete the following manual steps:

1. **Create a Unity Catalog metastore** in the [Databricks Account Console](https://accounts.azuredatabricks.net). A metastore is a top-level container for Unity Catalog metadata and is scoped to an Azure region. Only one metastore is required per region and it is shared across workspaces.

2. **Note the metastore ID** from the Account Console — it is needed when adding the `databricks_metastore_assignment` resource (added in a later stage).

3. **Ensure the app workspace is running** and that stage 2 and stage 3 have been applied successfully. This stage reads the `app_workspace_url` output from stage 2 remote state.

4. **Grant yourself the Account Admin role** in the Databricks Account Console so that Terraform can perform metastore operations.

This stage does **not** create the metastore itself — that is a one-time manual operation performed in the Account Console.

## Deployment

Copy `backend.conf.example` to `backend.conf` and fill in any environment-specific overrides, then initialise Terraform:

```bash
cp backend.conf.example backend.conf
terraform init -backend-config=backend.conf
terraform apply
```

`backend.conf` is excluded from version control via `.gitignore`.

## Remote State

The workspace URL is read automatically from stage 2 remote state (`workspace.terraform.tfstate`). No `-var` flags are required for the workspace URL.
