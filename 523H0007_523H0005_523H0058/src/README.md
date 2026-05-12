🚀 Final Project: Tier 4 E-Commerce Deployment on Docker SwarmDự án này triển khai hệ thống E-Commerce hoàn chỉnh trên AWS sử dụng kiến trúc Tier 4 (Multi-node Cluster). Toàn bộ hạ tầng được tự động hóa từ bước cấp phát tài nguyên đến triển khai ứng dụng.
📖 1. Giới thiệu sơ lượcHệ thống được thiết kế theo tiêu chuẩn sẵn sàng cao (High Availability), bao gồm cụm Docker Swarm đa nút (Manager & Workers) được bảo vệ bởi Traefik Load Balancer và hệ thống giám sát Prometheus/Grafana.

📋 2. Yêu cầu hệ thống (Prerequisites)Để triển khai đồ án này, máy tính cần cài đặt sẵn:Terraform (v1.0+) & AnsibleAWS CLI (đã cấu hình aws configure hoặc export Token từ Learner Lab)SSH Keypair (.pem): File khóa để truy cập EC2 (VD: vockey.pem)

🔐 3. Chuẩn bị tệp cấu hình (Setup Guide)Vì lý do bảo mật, các thông tin nhạy cảm đã được loại bỏ. Giảng viên vui lòng thực hiện các bước sau trước khi khởi chạy:

3.1 Cấu hình Terraform BackendTại thư mục gốc, tạo file backend.conf để lưu State trên S3 của Thầy/Cô:Ini, TOMLbucket         = "tên-bucket-s3-của-thầy-cô"
key            = "final-project/terraform.tfstate"
region         = "us-east-1"
use_lockfile   = true
encrypt        = true

3.2 Cấu hình Biến môi trườngVào thư mục final_code/, copy file .env.example thành .env:Bashcd final_code
cp .env.example .env
(Mặc định các biến đã được tối ưu cho Docker Swarm, Thầy/Cô có thể điều chỉnh PORT hoặc MongoDB URI nếu cần).🛠 
4. Các bước triển khai chi tiết
Bước 1: Cấp quyền và xác thực AWSBashchmod 400 <tên-file-key>.pem
# Export AWS Session Token (nếu dùng Learner Lab)
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_SESSION_TOKEN=""
Bước 2: Khởi tạo hạ tầng với Terraform Bash terraform init -backend-config=backend.conf
terraform apply -auto-approve
📌 Kết quả: Terraform sẽ tự động tạo các EC2 Instances và sinh ra file hosts.ini chứa IP của các máy chủ.
Bước 3: Cấu hình Swarm Cluster bằng AnsibleLệnh này sẽ tự động cài đặt Docker và thiết lập cụm Manager-Worker:Bashexport ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i hosts.ini swarm-setup.yml --private-key <tên-file-key>.pem
Bước 4: Copy Source Code & Deploy StackĐẩy thư mục code lên máy chủ Manager:Bashscp -i <tên-file-key>.pem -r ./final_code ubuntu@<MANAGER_IP>:/home/ubuntu/
SSH vào Manager và thực thi Deploy:Bashssh -i <tên-file-key>.pem ubuntu@<MANAGER_IP>
cd final_code
docker stack deploy -c docker-compose.yml ecommerce
🌐 5. Kiểm tra kết quả (Verification)Dịch vụĐịa chỉ truy cậpWebsite (Production)https://namcloud.xyz hoặc http://<MANAGER_IP>Visualizer (Swarm)http://<MANAGER_IP>:8083Grafana Dashboardhttp://<MANAGER_IP>:8080Lưu ý về SSL: Hệ thống sử dụng SSL Let's Encrypt cho domain namcloud.xyz. Nếu truy cập qua IP, vui lòng bỏ qua cảnh báo bảo mật của trình duyệt.🧹 
6. Hủy tài nguyên (Cleanup)Chạy lệnh sau tại máy local để tránh phát sinh chi phí AWS:Bashterraform destroy -auto-approve

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Public domain URL provided:::
https://namcloud.xyz

Monitoring dashboards:
https://monitor.namcloud.xyz/

LINK VIDEO DEMO:
https://drive.google.com/drive/folders/1idnFLmVolN7S2rsQqwu_TrWK9qffHphj?usp=sharing

LINK GitHub:
https://github.com/ngbao150205/final-deployment.git