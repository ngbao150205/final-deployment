## 🚀 Final Deployment – E-Commerce on Docker Swarm:
📌 Tổng quan

Dự án này triển khai hệ thống E-Commerce trên nền tảng Cloud AWS với kiến trúc hiện đại:

Terraform → Quản lý hạ tầng (Infrastructure as Code)
Ansible → Tự động cấu hình server
Docker Swarm → Orchestration & scaling
Node.js → Ứng dụng backend
Traefik → Reverse Proxy + SSL tự động

⚠️ Lưu ý bảo mật: Các file chứa thông tin nhạy cảm đã được loại khỏi Git. Bạn cần bổ sung thủ công trước khi chạy dự án.

## 📋 1. Yêu cầu hệ thống:

Đảm bảo máy đã cài đặt:

Terraform
Ansible
Node.js & npm
AWS CLI (nếu sử dụng Learner Lab)
## 🔐 2. Chuẩn bị Secret Files

Sau khi git clone, bạn sẽ thiếu một số file quan trọng.

📥 Liên hệ Team Lead để nhận:

labsuser.pem → SSH key truy cập server
backend.conf → cấu hình Terraform backend (S3)
.env → biến môi trường (DB, PORT, …)

👉 Sau khi nhận:

Copy toàn bộ vào thư mục gốc project
Không chỉnh sửa nếu không cần thiết
## 🛠 3. Thiết lập hạ tầng

### 🔑 3.1 Cấp quyền cho SSH Key
chmod 400 labsuser.pem

# export các key vào terminal::
export AWS_ACCESS_KEY_ID=""

export AWS_SECRET_ACCESS_KEY=""
    
export AWS_SESSION_TOKEN=""


### ☁️ 3.2 Khởi tạo Terraform
terraform init -backend-config=backend.conf

✅ Kết quả mong đợi:

Terraform has been successfully initialized!
### 🔍 3.3 Kiểm tra & đồng bộ hạ tầng
terraform plan

Nếu cần tạo lại hosts.ini:

terraform apply -auto-approve

📌 Sau bước này:

File hosts.ini sẽ được tạo tự động
### ⚙️ 3.4 Cấu hình Docker Swarm bằng Ansible
export ANSIBLE_HOST_KEY_CHECKING=False

ansible-playbook -i hosts.ini swarm-setup.yml

📌 Kết quả:

Các node được cài Docker
Swarm cluster được khởi tạo
## 🐳 4. Deploy ứng dụng

### 📤 4.1 Copy file lên Manager Node
scp -i labsuser.pem docker-compose.yml ubuntu@<MANAGER_IP>:~/

### 🔐 4.2 SSH vào server & deploy
ssh -i labsuser.pem ubuntu@<MANAGER_IP>

docker stack deploy -c docker-compose.yml ecommerce

### 📊 4.3 Kiểm tra hệ thống
# Danh sách services
docker service ls

# Chi tiết container app
docker service ps ecommerce_app

📌 Hệ thống sẽ:

Pull image: nbao1502/final:v1
Scale: 3 replicas
Phân bổ container trên nhiều node

## 🌐 5. Truy cập hệ thống
🌍 Website: https://namcloud.xyz

📊 Swarm Visualizer:

http://<MANAGER_IP>:8080