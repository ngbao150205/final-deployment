# --- FILE KHỞI TẠO HẠ TẦNG LƯU TRỮ (S3 & DYNAMODB) ---

# 1. Tạo S3 Bucket để lưu trữ State file
resource "aws_s3_bucket" "terraform_state" {
  bucket = "nbao-terraform-state-final" # Đảm bảo tên này duy nhất trên AWS

  # Ngăn chặn việc lỡ tay xóa bucket này qua lệnh destroy
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = "Terraform State Storage"
    ManagedBy   = "Terraform"
  }
}

# 2. Bật Versioning để có thể khôi phục các bản State cũ nếu bị lỗi
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. Tạo bảng DynamoDB để thực hiện tính năng Lock (khóa file khi có người đang sửa)
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
  }
}