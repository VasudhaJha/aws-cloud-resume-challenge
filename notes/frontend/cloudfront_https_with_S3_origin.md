# Use Cloudfront to serve the website, with the s3 bucket acting as the origin

This step of the Cloud Resume Challenge involves setting up Amazon CloudFront to serve the static website securely over HTTPS since S3 static website hosting only supports HTTP.

```text
5. HTTPS
The S3 website URL should use HTTPS for security. You will need to use Amazon CloudFront to help with this.
```

By doing this we can serve secure, cached content via CloudFront while keeping the S3 bucket private.

To do this:

## Step 1: Remove Static Website Hosting from S3

CloudFront should fetch content directly from the S3 bucket, not the website endpoint. Since the website endpoint is no longer required we remove it from the Terraform configuration:

```hcl
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.cloud-resume-bucket.id

  index_document {
    suffix = "index.html"
  }
}
```

## Step 2: Configure CloudFront with the S3 Bucket as the Origin

CloudFront should be able to retrieve objects from the private S3 bucket.

Terraform configuration for CloudFront:

```hcl
resource "aws_cloudfront_origin_access_control" "cloud-resume-oac" {
  name                              = "cloud-resume-oac"
  description                       = "OAC for private S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
```

This allows CloudFront to sign requests to S3 securely.

Now, attaching this to the CloudFront distribution:

```hcl
resource "aws_cloudfront_distribution" "cloud-resume-distribution" {
  origin {
    domain_name              = aws_s3_bucket.cloud-resume-bucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.cloud-resume-bucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.cloud-resume-oac.id
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.cloud-resume-bucket.id}"
    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    cloudfront_default_certificate = true  # Uses CloudFront's default *.cloudfront.net SSL certificate
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"  # No country restrictions
    }
  }
}
```

CloudFront will now serve content from S3 and enforce HTTPS.

## Step 3: Update S3 Bucket Policy to Allow CloudFront Access

Since the S3 bucket is private, it must explicitly allow CloudFront to fetch objects.

Terraform configuration for the updated S3 bucket policy:

```hcl
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
```

Now, only CloudFront can fetch objects from S3—keeping the bucket secure.

## Step 4: Verify That HTTPS Is Working

Run this command to check if CloudFront is serving content securely:

```bash
curl -I https://YOUR_CLOUDFRONT_ID.cloudfront.net/index.html
```

If you see HTTP/2 200 OK, HTTPS is enabled successfully!

## Challenges Faced and Solutions

1. 403 Forbidden Error from CloudFront
Problem: CloudFront could not access S3 objects.
Solution: Updating the S3 bucket policy to explicitly allow CloudFront requests solved the issue.

1. "Miss from CloudFront" Instead of "Hit"
Problem: CloudFront was not caching responses efficiently.
Solution: Adding a cache policy improved performance.

```hcl
default_cache_behavior {
  cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"  # AWS Managed CachingOptimized
}
```

This reduced S3 costs and improved load times.

## Final Terraform Configuration for This Step

```hcl
resource "aws_cloudfront_origin_access_control" "cloud-resume-oac" {
  name                              = "cloud-resume-oac"
  description                       = "OAC for private S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cloud-resume-distribution" {
  origin {
    domain_name              = aws_s3_bucket.cloud-resume-bucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.cloud-resume-bucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.cloud-resume-oac.id
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.cloud-resume-bucket.id}"
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"  # AWS Managed CachingOptimized
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

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
```

Now, CloudFront serves the S3 static website securely over HTTPS with caching enabled.
