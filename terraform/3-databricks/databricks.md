# Databricks Workspace Setup

This stage of the Terraform Pipeline is to govern the deployment of resources within Databricks itself. This includes things such as clusters, sql warehouses, workspace settings.

Depending on your setup, you may include Unity Catalog objects and permissions within this step, however I would suggest that they are separated out into their own projects (Unity is not tightly tied to an individual workspace.)

You could also use this to deploy Databricks Workflows and DLT. This is not really best governed by Terraform, and tools such as Databricks Asset Bundles (DABS) work better for application code.

### Prerequisites
This is the first step that includes the Databricks Provider. The Azure is kept in case there is a requirement to deploy storage accounts or similar for use by the workspace as an external location.

Before running this stage you will need to do the following:
- Link your workspace to an established Unity Catalog metastore for your environment
- Grant permissions to your account within the workspace
