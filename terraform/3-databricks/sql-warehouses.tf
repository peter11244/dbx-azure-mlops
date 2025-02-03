resource "databricks_sql_endpoint" "serverless-main" {
    name = "serverless-main"
    cluster_size = "2X-Small"
    enable_serverless_compute = true
}