locals {
  tags = merge({ managed_by = "cloudcron" }, var.tags)
  topic_names = {
    for key, name in var.topic_names :
    key => !endswith(name, ".fifo") ? "${name}.fifo" : name
  }
}

resource "aws_sns_topic" "topics" {
  for_each = local.topic_names

  name                        = each.value
  fifo_topic                  = true
  content_based_deduplication = true
  tags                        = local.tags
}
