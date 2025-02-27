# Create the bucket to act as the remote backend
resource "aws_s3_bucket" "remote-backend" {
  bucket = "aws-cloud-resume-remote-backend"
}

# add object versioning for the state files
resource "aws_s3_bucket_versioning" "remote-backend-versioning" {
  bucket = aws_s3_bucket.remote-backend.id

  versioning_configuration {
    status = "Enabled"
  }
}

# create the dynamodb table for state locking
resource "aws_dynamodb_table" "state-locking-table" {
  name = "aws-cloud-resume-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
}

