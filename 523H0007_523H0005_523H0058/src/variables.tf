# --- Biến định danh môi trường ---
variable "environment" {
  description = "Tên môi trường triển khai (vd: dev, staging, prod)"
  type        = string
  default     = "prod" 
}

# --- Biến loại máy ảo (Instance Type) ---
variable "instance_type" {
  description = "Loại EC2 instance sử dụng cho các node"
  type        = string
  default     = "t2.micro" # t2.micro nằm trong gói Free Tier, phù hợp với AWS Learner Lab
}

# --- Biến tên SSH Key Pair (CỰC KỲ QUAN TRỌNG) ---
variable "key_name" {
  description = "Tên của AWS Key Pair để SSH vào máy ảo"
  type        = string
  # Lưu ý: Bạn PHẢI tạo một Key Pair trên AWS Console trước (ví dụ tên là "my-aws-key") 
  # và điền tên đó vào đây khi chạy, nếu không bạn sẽ không thể remote vào server.
  default     = "vockey" # 'vockey' thường là key mặc định trong môi trường AWS Learner Lab, hãy kiểm tra lại trên console của bạn.
}
