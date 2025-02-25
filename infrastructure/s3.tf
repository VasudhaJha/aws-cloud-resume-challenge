# Create the s3 bucket
resource "aws_s3_bucket" "cloud-resume-bucket" {
    bucket = "aws-cloud-resume-challenge-vasudha"
}

# Enable bucket versioning
resource "aws_s3_bucket_versioning" "cloud-resume-bucket" {
  bucket = aws_s3_bucket.cloud-resume-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access to make it private
# (We will add a policy later to allow only cloudfront to access it and use it as origin)

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.cloud-resume-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


# Set up server side encryption for s3 so that objects in bucket are encrypted at rest
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.cloud-resume-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Dynamically Get the AWS Account ID using the AWS STS (Security Token Service) caller identity
data "aws_caller_identity" "current" {}

# Write the bucket policy to allow objects inside the bucket to be publicly accessible
resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = aws_s3_bucket.cloud-resume-bucket.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.cloud-resume-bucket.id}/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cloud-resume-distribution.id}"
        }
      }
    }
  ]
}
EOF
}

# Uploading the resume html file and css files to s3 since they won't change
resource "aws_s3_object" "resume-file" {
  bucket = aws_s3_bucket.cloud-resume-bucket.id
  key    = "index.html"
  source = "../src/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "css-file" {
  bucket = aws_s3_bucket.cloud-resume-bucket.id
  key    = "css/styles.css"
  source = "../src/css/styles.css"
  content_type = "text/css"
}

