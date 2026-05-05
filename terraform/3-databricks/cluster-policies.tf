resource "databricks_instance_pool" "shared" {
  instance_pool_name                    = "${var.naming_prefix}-shared-pool"
  min_idle_instances                    = 0
  max_capacity                          = 10
  idle_instance_autotermination_minutes = 10

  azure_attributes {
    availability = "SPOT_AZURE"
  }

  node_type_id = "Standard_DS3_v2"
}

resource "databricks_cluster_policy" "single_node" {
  name = "${var.naming_prefix}-single-node"

  definition = jsonencode({
    "spark_version" = {
      "type"  = "unlimited"
      "value" = "auto:latest-lts"
    }
    "num_workers" = {
      "type"  = "fixed"
      "value" = 0
    }
    "spark_conf.spark.databricks.cluster.profile" = {
      "type"  = "fixed"
      "value" = "singleNode"
    }
    "spark_conf.spark.master" = {
      "type"  = "fixed"
      "value" = "local[*]"
    }
    "autotermination_minutes" = {
      "type"         = "range"
      "minValue"     = 10
      "maxValue"     = 120
      "defaultValue" = 30
    }
    "instance_pool_id" = {
      "type"  = "fixed"
      "value" = databricks_instance_pool.shared.id
    }
  })
}

resource "databricks_cluster_policy" "standard" {
  name = "${var.naming_prefix}-standard"

  definition = jsonencode({
    "spark_version" = {
      "type"  = "unlimited"
      "value" = "auto:latest-lts"
    }
    "num_workers" = {
      "type"         = "range"
      "minValue"     = 1
      "maxValue"     = 8
      "defaultValue" = 2
    }
    "autotermination_minutes" = {
      "type"         = "range"
      "minValue"     = 10
      "maxValue"     = 120
      "defaultValue" = 30
    }
    "instance_pool_id" = {
      "type"  = "fixed"
      "value" = databricks_instance_pool.shared.id
    }
  })
}
