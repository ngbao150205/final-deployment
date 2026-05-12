# --- Xuất IP Tĩnh (Elastic IP) của Manager Node ---
output "swarm_manager_public_ip" {
  description = "Địa chỉ IP Public (IP Tĩnh) của Manager Node. Dùng IP này để gán vào Domain."
  value       = aws_eip.manager_ip.public_ip
}

# --- Xuất IP Private của Manager Node ---
output "swarm_manager_private_ip" {
  description = "Địa chỉ IP Private của Manager Node. Dùng để cấu hình mạng nội bộ cho Swarm (Advertise Address)."
  value       = aws_instance.swarm_manager.private_ip
}

# --- Xuất danh sách IP Public của các Worker Nodes ---
output "swarm_workers_public_ips" {
  description = "Danh sách IP Public của các máy Worker để Ansible có thể SSH vào cấu hình."
  value       = aws_instance.swarm_workers[*].public_ip
}

# --- Xuất danh sách IP Private của các Worker Nodes ---
output "swarm_workers_private_ips" {
  description = "Danh sách IP Private của các máy Worker."
  value       = aws_instance.swarm_workers[*].private_ip
}
