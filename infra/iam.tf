data "aws_iam_policy_document" "ecs_tasks_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_role" {
  name               = "wishifai-task-role-${var.kandidatnummer}"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_trust.json
}

data "aws_iam_policy_document" "task_permissions" {
  statement {
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${aws_s3_bucket.images.arn}/*"]
  }

  statement {
    actions   = ["rekognition:DetectLabels"]
    resources = ["*"]
  }

  statement {
    actions   = ["bedrock:InvokeModel", "bedrock:Converse"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "task_policy" {
  name   = "wishifai-task-policy-${var.kandidatnummer}"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.task_permissions.json
}
