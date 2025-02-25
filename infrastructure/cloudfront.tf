# Create an OAC for cloudfront
resource "aws_cloudfront_origin_access_control" "cloud-resume-oac" {
  name                              = "cloud-resume-oac"
  description                       = "OAC for private s3 bucket"
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

    min_ttl      = 3600    # Cache for at least 1 hour
    default_ttl  = 86400   # Default cache time = 1 day
    max_ttl      = 31536000  # Max cache time = 1 year

    # forwarded_values tells CloudFront what request information to forward to the origin.
    # By default, CloudFront does not forward these values unless explicitly configured.
    # Since static websites don't change based on query parameters or cookies, these values don’t need to be forwarded.
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # Uses CloudFront's default *.cloudfront.net SSL certificate
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" # No country restrictions
    }
  }
}


# Bucket regional domain name looks like this: <bucket-name>.s3.<region>.amazonaws.com
# enabled=true means distribution is active and ready to serve content
# target_origin_id links the cache behavior to the correct origin (S3 bucket in this case).
