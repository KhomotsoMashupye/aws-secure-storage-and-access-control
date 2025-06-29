

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region to deploy into"
  default     = "af-south-1"
}



resource "aws_s3_bucket" "logging" {
  bucket        = "tirelongtechnology-logs"
  force_destroy = true
  tags = {
    Owner       = "Khomotso-TirelongAdmin"
    Environment = "Production"
  }
}

resource "aws_s3_bucket" "main" {
  bucket        = "tirelongtechnology215"
  force_destroy = true
  tags = {
    Owner       = "Khomotso-TirelongAdmin"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "main" {
  bucket        = aws_s3_bucket.main.id
  target_bucket = aws_s3_bucket.logging.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    id     = "archive"
    status = "Enabled"
    transition {
      days          = 365
      storage_class = "GLACIER"
    }
  }
}



resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name              = "/aws/cloudtrail/tirelong"
  retention_in_days = 90
}

resource "aws_iam_role" "cloudtrail_role" {
  name = "cloudtrail-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "cloudtrail.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_policy" {
  name = "cloudtrail-policy"
  role = aws_iam_role.cloudtrail_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["logs:CreateLogStream", "logs:PutLogEvents"],
      Resource = "*"
    }]
  })
}

resource "aws_cloudtrail" "main" {
  name                          = "tirelong-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.main.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.cloudtrail_logs.arn
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_role.arn

  depends_on = [
    aws_cloudwatch_log_group.cloudtrail_logs,
    aws_iam_role.cloudtrail_role,
    aws_iam_role_policy.cloudtrail_policy
  ]
}


locals {
  doctors   = ["dr_danny_lerutla", "dr_anna_mekwe"]
  admins    = ["retang_mmutla", "amanda_mei"]
  reception = ["dolly_atkinson"]
  it_team   = ["khomotso_mashupye", "jason_matlala"]
  all_users = concat(local.doctors, local.admins, local.reception, local.it_team)
}

resource "aws_iam_user" "users" {
  for_each = toset(local.all_users)
  name     = each.key
}

resource "aws_iam_user_login_profile" "logins" {
  for_each = aws_iam_user.users
  user                    = each.key
  password_reset_required = true
}

resource "aws_iam_group" "groups" {
  for_each = toset(["doctors", "admins", "reception", "it"])
  name     = each.key
}

resource "aws_iam_user_group_membership" "group_membership" {
  for_each = merge(
    { for u in local.doctors   : u => "doctors" },
    { for u in local.admins    : u => "admins" },
    { for u in local.reception : u => "reception" },
    { for u in local.it_team   : u => "it" }
  )
  user   = each.key
  groups = [aws_iam_group.groups[each.value].name]
}

data "aws_iam_policy_document" "doctor_policy" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "admin_policy" {
  statement {
    actions   = ["*"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "reception_policy" {
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "it_policy" {
  statement {
    actions   = ["s3:*", "cloudtrail:*", "cloudwatch:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "doctor" {
  name   = "doctor-policy"
  policy = data.aws_iam_policy_document.doctor_policy.json
}

resource "aws_iam_policy" "admin" {
  name   = "admin-policy"
  policy = data.aws_iam_policy_document.admin_policy.json
}

resource "aws_iam_policy" "reception" {
  name   = "reception-policy"
  policy = data.aws_iam_policy_document.reception_policy.json
}

resource "aws_iam_policy" "it" {
  name   = "it-policy"
  policy = data.aws_iam_policy_document.it_policy.json
}

resource "aws_iam_group_policy_attachment" "attach_doctor" {
  group      = aws_iam_group.groups["doctors"].name
  policy_arn = aws_iam_policy.doctor.arn
}

resource "aws_iam_group_policy_attachment" "attach_admin" {
  group      = aws_iam_group.groups["admins"].name
  policy_arn = aws_iam_policy.admin.arn
}

resource "aws_iam_group_policy_attachment" "attach_reception" {
  group      = aws_iam_group.groups["reception"].name
  policy_arn = aws_iam_policy.reception.arn
}

resource "aws_iam_group_policy_attachment" "attach_it" {
  group      = aws_iam_group.groups["it"].name
  policy_arn = aws_iam_policy.it.arn
}



resource "aws_cloudwatch_metric_alarm" "s3_bucket_size" {
  alarm_name          = "S3BucketSizeAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = 86400
  statistic           = "Average"
  threshold           = 10000000000
  alarm_description   = "Triggers when S3 bucket size exceeds 10GB"
  dimensions = {
    BucketName  = aws_s3_bucket.main.bucket
    StorageType = "StandardStorage"
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "s3_object_created" {
  alarm_name          = "S3ObjectCreatedAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Triggers when an object is created"
  dimensions = {
    BucketName  = aws_s3_bucket.main.bucket
    StorageType = "AllStorageTypes"
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}



resource "aws_sns_topic" "alerts" {
  name = "tirelong-alerts-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "inquiries@tirelongtechnologies.com"
}



resource "aws_budgets_budget" "monthly_cost_budget" {
  name              = "MonthlyCostBudget"
  budget_type       = "COST"
  limit_amount      = "100"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 80
    threshold_type      = "PERCENTAGE"
    notification_type   = "ACTUAL"

    subscribers {
      address           = "inquiries@tirelongtechnologies.com"
      subscription_type = "EMAIL"
    }
  }

  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 100
    threshold_type      = "PERCENTAGE"
    notification_type   = "ACTUAL"

    subscribers {
      address           = "inquiries@tirelongtechnologies.com"
      subscription_type = "EMAIL"
    }
  }
}
#SET UP BUDGETS MANUALLY
