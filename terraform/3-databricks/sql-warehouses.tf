resource "databricks_sql_endpoint" "serverless-main" {
    name = "serverless-main"
    cluster_size = "2X-Small"
    warehouse_type = "PRO"
    auto_stop_mins = 10
    enable_serverless_compute = true
}