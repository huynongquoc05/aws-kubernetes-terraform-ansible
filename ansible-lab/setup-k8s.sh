#!/bin/bash

echo "🚀 BẮT ĐẦU CÀI ĐẶT MÔI TRƯỜNG KUBERNETES..."

# ---------------------------------------------------------
# 1. TẮT SWAP (Yêu cầu bắt buộc của K8s)
# ---------------------------------------------------------
echo "[1/5] Đang tắt Swap..."
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# ---------------------------------------------------------
# 2. CẤU HÌNH MODULE KERNEL & ĐỊNH TUYẾN MẠNG
# ---------------------------------------------------------
echo "[2/5] Đang cấu hình Kernel Modules và Sysctl..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# ---------------------------------------------------------
# 3. CÀI ĐẶT CONTAINERD (Container Runtime)
# ---------------------------------------------------------
echo "[3/5] Đang cài đặt containerd..."
sudo apt-get update -y
sudo apt-get install -y containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Bật cgroup systemd cho containerd (Thay thế 'SystemdCgroup = false' thành 'true')
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# ---------------------------------------------------------
# 4. THÊM KHO LƯU TRỮ KUBERNETES (v1.30)
# ---------------------------------------------------------
echo "[4/5] Đang thiết lập kho lưu trữ Kubernetes..."
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p -m 755 /etc/apt/keyrings

# Xóa key cũ nếu có để tránh lỗi khi chạy lại script
sudo rm -f /etc/apt/keyrings/kubernetes-archive-keyring.gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# ---------------------------------------------------------
# 5. CÀI ĐẶT BỘ CÔNG CỤ K8S VÀ KHÓA PHIÊN BẢN
# ---------------------------------------------------------
echo "[5/5] Đang cài đặt kubelet, kubeadm, kubectl..."
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

echo "✅ HOÀN TẤT! HỆ THỐNG ĐÃ SẴN SÀNG CHO KUBERNETES."