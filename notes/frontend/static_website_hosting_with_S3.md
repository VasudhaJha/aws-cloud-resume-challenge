# Static Website Hosting with S3

This is what step 4 of the challenge tells us to do:

```text
4. Static Website
Your HTML resume should be deployed online as an Amazon S3 static website. Services like Netlify and GitHub Pages are great and I would normally recommend them for personal static site deployments, but they make things a little too abstract for our purposes here. Use S3.
```

Upon enabling static website hosting on an S3 bucket, it provides an endpoint like:

`http://<your-bucket-name>.s3-website.<region>.amazonaws.com`

However, just enabling it is not enough—permissions need to be set correctly.

Even after turning off Block Public Access, your S3 bucket still denies public access by default because:

- S3 Bucket Policy is Missing → The bucket needs a policy to allow public reads.

To Make the S3 Static Website Public:

Step 1: Enable Static Website Hosting on S3

Step 2: Update the Bucket Policy for Public Access

## Step 1: Enable Static Website Hosting

In the terraform configuration file, the S3 bucket is defined with static website hosting:

```hcl
resource "aws_s3_bucket" "resume" {
  bucket = "my-resume-bucket"
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.resume.id

  index_document {
    suffix = "index.html"
  }

}
```

This enables static website hosting, but does **NOT** make it public yet.

## Step 2: Update the S3 Bucket Policy

Now, we need to allow the world to access the website:

```hcl

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.resume.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-resume-bucket/*"
    }
  ]
}
EOF
}
```

## Challenge Faced: IAM Permissions for Applying the Bucket Policy

Terraform threw a `403 AccessDenied` error when trying to attach the bucket policy.
Even though my IAM user had `AdministratorAccess`, AWS blocked public policies by default.

To resolve it, I did the following:

1. Setting the block all public access to False in the terraform configuration

```hcl
resource "aws_s3_bucket_public_access_block" "resume_public_access" {
  bucket = aws_s3_bucket.cloud-resume-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
```

1. Creating an IAM Policy to explicitly grant s3:PutBucketPolicy permission to my IAM user:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutBucketPolicy",
                "s3:GetBucketPolicy",
                "s3:DeleteBucketPolicy"
            ],
            "Resource": "arn:aws:s3:::my-resume-bucket"
        }
    ]
}
```

After attaching this policy, Terraform successfully applied the S3 bucket policy.

Here's the complete Terraform configuration for this step:

```HCL
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

# Terraform documentation says that block public access is set to False (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block), but we need to explicitly define it because it does not work and will not let you apply the bucket policy later

resource "aws_s3_bucket_public_access_block" "resume_public_access" {
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

# Enable static website hosting
resource "aws_s3_bucket_website_configuration" "website-configuration" {
  bucket = aws_s3_bucket.cloud-resume-bucket.id

  index_document {
    suffix = "index.html"
  }
}

# Write the bucket policy to allow objects inside the bucket to be publicly accessible
resource "aws_s3_bucket_policy" "bucket-policy" {
  bucket = aws_s3_bucket.cloud-resume-bucket.id
  policy = <<EOF
  {
    "Version" : "2012-10-17",
    "Statement": [
        {
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : "s3:GetObject",
          "Resource" : "arn:aws:s3:::aws-cloud-resume-challenge-vasudha/*"
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
```
