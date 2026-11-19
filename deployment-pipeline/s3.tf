resource "aws_s3_bucket" "pipeline" {
  bucket = local.pipeline_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = local.pipeline_bucket_name
    Environment = var.ENVIRONMENT
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline" {
  count = var.S3_PUBLIC_ACCESS_BLOCK_ENABLED ? 1 : 0

  bucket                  = aws_s3_bucket.pipeline.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "pipeline" {
  count = var.S3_VERSIONING_ENABLED ? 1 : 0

  bucket = aws_s3_bucket.pipeline.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline" {
  count = var.S3_ENCRYPTION_ENABLED ? 1 : 0

  bucket = aws_s3_bucket.pipeline.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.pipeline.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_policy" "pipeline" {
  count = var.S3_ENFORCE_SSL_ONLY ? 1 : 0

  bucket = aws_s3_bucket.pipeline.id
  policy = data.aws_iam_policy_document.pipeline_bucket_policy.json
}

data "aws_iam_policy_document" "pipeline_bucket_policy" {
  statement {
    sid    = "DenyNonSSL"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.pipeline.arn, "${aws_s3_bucket.pipeline.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "pipeline" {
  count = var.S3_LIFECYCLE_ENABLED ? 1 : 0

  bucket = aws_s3_bucket.pipeline.id

  rule {
    id     = "expire-old-plans"
    status = "Enabled"
    filter { prefix = "plans/" }
    expiration { days = 30 }
    noncurrent_version_expiration { noncurrent_days = 30 }
  }

  rule {
    id     = "expire-old-artifacts"
    status = "Enabled"
    filter { prefix = "artifacts/" }
    expiration { days = 30 }
  }
}

