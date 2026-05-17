resource "aws_s3_bucket" "forensics" {
  bucket = "itai-cloud-ops-forensics"

  tags = {
    Name = "cloud-ops-forensics"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.forensics.id

  versioning_configuration {
    status = "Enabled"
  }
}

