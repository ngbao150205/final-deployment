# Tạm thời comment Remote Backend nếu AWS Learner Lab báo lỗi IAM Permission

terraform {
  backend "s3" {} # Để trống hoàn toàn ở đây để dùng backend.conf
}

provider "aws" {
  region = "us-east-1"
}

locals {
  common_tags = {
    Project     = "E-Commerce-App"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# --- 1. Tạo Security Group hỗ trợ Docker Swarm ---
resource "aws_security_group" "swarm_sg" {
  name        = "${var.environment}-swarm-sg"
  description = "Security Group for Docker Swarm Cluster"

  # Các port public cho User bên ngoài truy cập (SSH, HTTP, HTTPS, Web App)
  dynamic "ingress" {
    for_each = [22, 80, 443, 8080, 9090] # Đã tự động thêm cả 9090 theo logs của bạn
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # --- CÁC PORT NỘI BỘ CỦA SWARM ---
  # Chỉ cho phép các node trong cùng Security Group giao tiếp (self = true)

  # Port quản lý cụm Swarm
  ingress {
    description = "Swarm Manager Node management"
    from_port   = 2377
    to_port     = 2377
    protocol    = "tcp"
    self        = true
  }

  # Port giao tiếp giữa các node (TCP & UDP)
  ingress {
    description = "Swarm Node communication (TCP)"
    from_port   = 7946
    to_port     = 7946
    protocol    = "tcp"
    self        = true
  }
  
  ingress {
    description = "Swarm Node communication (UDP)"
    from_port   = 7946
    to_port     = 7946
    protocol    = "udp"
    self        = true
  }

  # Port cho Overlay Network của Swarm (UDP)
  ingress {
    description = "Swarm Overlay Network traffic"
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 2. Tạo 1 Node Manager ---
resource "aws_instance" "swarm_manager" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.swarm_sg.id]

  root_block_device {
    volume_size = 16
    volume_type = "gp3" 
  }

  # ==============================================================
  # SCRIPT TỰ ĐỘNG CÀI ĐẶT GITHUB SELF-HOSTED RUNNER KHI KHỞI ĐỘNG
  # (Chèn thêm đoạn này vào, các dòng khác giữ nguyên)
  # ==============================================================
  user_data = <<-EOF
    #!/bin/bash
    # 1. Cập nhật hệ thống và cài đặt Docker (để Runner có thể build image)
    apt-get update -y
    apt-get install -y docker.io curl libicu-dev
    usermod -aG docker ubuntu
    systemctl enable docker
    systemctl start docker

    # 2. Tạo thư mục cho Github Runner
    mkdir -p /home/ubuntu/actions-runner
    cd /home/ubuntu/actions-runner

    # 3. Tải Github Runner package
    curl -o actions-runner-linux-x64-2.316.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.316.1/actions-runner-linux-x64-2.316.1.tar.gz
    tar xzf ./actions-runner-linux-x64-2.316.1.tar.gz

    # Cấp quyền cho user ubuntu (GitHub bắt buộc không được chạy Runner bằng quyền root)
    chown -R ubuntu:ubuntu /home/ubuntu/actions-runner

    # 4. Cấu hình Runner (BẠN PHẢI THAY URL VÀ TOKEN Ở DÒNG DƯỚI KHI DÙNG THỰC TẾ)
    su - ubuntu -c "/home/ubuntu/actions-runner/config.sh --url https://github.com/YOUR_GITHUB_NAME/YOUR_REPO_NAME --token YOUR_GITHUB_TOKEN --unattended --replace"

    # 5. Cài đặt thành Service ngầm và Khởi động
    cd /home/ubuntu/actions-runner
    ./svc.sh install ubuntu
    ./svc.sh start
  EOF

  # BẢO VỆ SERVER: Bỏ qua nếu có sự thay đổi về AMI
  lifecycle {
    ignore_changes = [ami]
  }

  tags = merge(local.common_tags, { Name = "${var.environment}-swarm-manager" })
}

# --- 3. Tạo 2 Node Workers bằng vòng lặp count ---
resource "aws_instance" "swarm_workers" {
  count         = 2 # Tạo ra 2 máy worker
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.swarm_sg.id]

  # BẢO VỆ SERVER: Bỏ qua nếu có sự thay đổi về AMI
  lifecycle {
    ignore_changes = [ami]
  }

  tags = merge(local.common_tags, { Name = "${var.environment}-swarm-worker-${count.index + 1}" })
}

# --- 4. Gán IP tĩnh (EIP) cho DUY NHẤT Node Manager ---
resource "aws_eip" "manager_ip" {
  instance = aws_instance.swarm_manager.id
  domain   = "vpc"
  tags     = merge(local.common_tags, { Name = "${var.environment}-manager-eip" })
}

# --- 5. Tự động sinh file hosts.ini cho Ansible ---
resource "local_file" "ansible_inventory" {
  content = <<-DOC
    [managers]
    manager ansible_host=${aws_eip.manager_ip.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=./labsuser.pem

    [workers]
    worker1 ansible_host=${aws_instance.swarm_workers[0].public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=./labsuser.pem
    worker2 ansible_host=${aws_instance.swarm_workers[1].public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=./labsuser.pem
  DOC
  filename = "${path.module}/hosts.ini"
}