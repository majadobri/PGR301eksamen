resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "marija"
  dashboard_body = <<DASHBOARD
{
  "widgets": [
    {
      "type": "metric",
      "x": 0, "y": 0, "width": 12, "height": 6,
      "properties": {
        "title": "Business: bilder analysert og gaveforslag",
        "metrics": [
          [ "marija", "images_analyzed.count", { "label": "Bilder analysert" } ],
          [ "marija", "gift_suggestions_per_analysis.sum", { "label": "Gaveforslag" } ]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "${var.region}"
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 0, "width": 12, "height": 6,
      "properties": {
        "title": "Snittid Rekognition og Bedrock (ms)",
        "metrics": [
          [ "marija", "rekognition_latency.avg", { "label": "Rekognition" } ],
          [ "marija", "bedrock_latency.avg", { "label": "Bedrock" } ]
        ],
        "period": 60,
        "stat": "Average",
        "region": "${var.region}"
      }
    },
    {
      "type": "metric",
      "x": 0, "y": 6, "width": 12, "height": 6,
      "properties": {
        "title": "Applikasjon (Actuator): CPU-bruk og tråder i JVM",
        "metrics": [
          [ "marija", "process.cpu.usage.value" ],
          [ "marija", "jvm.threads.live.value" ]
        ],
        "period": 60,
        "stat": "Average",
        "region": "${var.region}"
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 6, "width": 12, "height": 6,
      "properties": {
        "title": "Infrastruktur: ECS CPU og minne (%)",
        "metrics": [
          [ { "expression": "SEARCH('{AWS/ECS,ClusterName,ServiceName} ServiceName=\"${aws_ecs_express_gateway_service.wishifai.service_name}\"', 'Average', 60)", "id": "e1" } ]
        ],
        "period": 60,
        "region": "${var.region}"
      }
    }
  ]
}
DASHBOARD
}

resource "aws_cloudwatch_metric_alarm" "bedrock_latency" {
  alarm_name          = "marija-bedrock-latency"
  alarm_description   = "Gjennomsnittlig Bedrock-tid er over 20 sekunder"
  namespace           = "marija"
  metric_name         = "bedrock_latency.avg"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = 20000
  treat_missing_data  = "notBreaching"
}
