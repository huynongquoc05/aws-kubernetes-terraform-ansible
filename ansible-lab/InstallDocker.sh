#!/bin/bash
# 1. Cập nhật hệ thống và cài các gói phụ trợ cần thiết

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# 2. Tạo thư mục và tải về khóa GPG chính thức của Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 3. Thêm Docker Repository vào danh sách nguồn cấp apt
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. Cập nhật lại apt và tiến hành cài đặt Docker + Docker Compose Plugin
sudo apt-get update
sudo apt-get -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" install -y docker-ce docker-ce-cli containerd.io
# 5. Cấu hình phân quyền để user hiện tại chạy được docker không cần sudo
sudo usermod -aG docker $USER
newgrp docker

# 6. Đảm bảo Docker tự bật khi khởi động máy
sudo systemctl enable docker