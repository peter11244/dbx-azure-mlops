# Structure

The purpose of this Terraform project is to be run seperately and before all the other projects in this repo.

`This uses a local statefile. You should run this manually prior to the other stages`

You need to grant RBAC permission on this storage container after creation. (Could Automate?!)

## Variables

| Variable | Default | Description |
|---|---|---|
| `subscription_id` | `972bbe39-991c-4055-80b8-ab36598f89c3` | Azure subscription ID |
| `tenant_id` | `6d2c78dd-1f85-4ccb-9ae3-cd5ea1cca361` | Azure Entra ID tenant ID |

Override these at plan/apply time with `-var` flags or a `.tfvars` file when targeting a different subscription or tenant.

