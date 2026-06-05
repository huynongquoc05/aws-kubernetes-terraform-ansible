# =====================================================================
# KHỐI RESOURCES - CỤM MÁY CHỦ KUBERNETES
# =====================================================================

# 1. Máy chủ Control Plane (Master Node)
resource "aws_instance" "control_plane" {
  ami                    = var.cluster_ami
  instance_type          = var.master_instance_type
  subnet_id              = var.subnet_zone_a
  key_name               = var.instance_key_name
  vpc_security_group_ids = [aws_security_group.cluster_sec_g.id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  tags = {
    Name = "CONTROL_NODE1"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# 2. Máy chủ Worker Node 1
resource "aws_instance" "worker_node1_ec2" {
  ami                    = var.cluster_ami
  instance_type          = var.worker_instance_type
  subnet_id              = var.subnet_zone_a
  key_name               = var.instance_key_name
  vpc_security_group_ids = [aws_security_group.cluster_sec_g.id]

  root_block_device {
    volume_size = 15
    volume_type = var.root_volume_type
  }

  tags = {
    Name = "WORK_NODE1"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# 3. Máy chủ Worker Node 2 (Con máy cấu hình đặc biệt)
resource "aws_instance" "worker_node2_ec2" {
  ami                    = var.cluster_ami
  instance_type          = var.worker2_instance_type # Dùng cấu hình to c7i-flex
  subnet_id              = var.subnet_zone_b        # Nằm ở subnet khác biệt của nó
  key_name               = var.instance_key_name
  vpc_security_group_ids = [aws_security_group.cluster_sec_g.id]

  # Con worker2 lúc trước bạn show không thấy khai báo block device,
  # nhưng nếu thực tế nó dùng mặc định giống tụi kia thì cứ giữ nguyên/hoặc tiêm biến vào nhé.

  tags = {
    Name = "WORK_NODE2"
  }

  lifecycle {
    prevent_destroy = true
  }
  root_block_device {
    volume_size = 15
    volume_type = var.root_volume_type
  }
}

# =====================================================================
# KHỐI TRẠNG THÁI - ĐIỀU KHIỂN BẬT/TẮT TẬP TRUNG
# =====================================================================

resource "aws_ec2_instance_state" "control_plane_state" {
  instance_id = aws_instance.control_plane.id
  state       = var.cluster_instance_state
}

resource "aws_ec2_instance_state" "worker_node1_state" {
  instance_id = aws_instance.worker_node1_ec2.id
  state       = var.cluster_instance_state
}

resource "aws_ec2_instance_state" "worker_node2_state" {
  instance_id = aws_instance.worker_node2_ec2.id
  state       = var.cluster_instance_state
}

data "aws_instance" "control_plane_live" {
  instance_id = aws_instance.control_plane.id
  # Ép con thám tử này phải đợi máy chuyển sang trạng thái running xong mới được đi tra cứu
  depends_on  = [aws_ec2_instance_state.control_plane_state]
}

data "aws_instance" "worker_node1_live" {
  instance_id = aws_instance.worker_node1_ec2.id
  depends_on  = [aws_ec2_instance_state.worker_node1_state]
}

data "aws_instance" "worker_node2_live" {
  instance_id = aws_instance.worker_node2_ec2.id
  depends_on  = [aws_ec2_instance_state.worker_node2_state]
}



# =====================================================================
# 3. KHỐI securityG
# =====================================================================
resource "aws_security_group" "cluster_sec_g" {
  name        = "launch-wizard-2"
  description = "launch-wizard-2 created 2026-05-29T09:12:09.997Z"
  vpc_id      = var.vpc_id

  # --- CHIỀU ĐI VÀO (INBOUND RULES / INGRESS) ---

  # 1. Mở cổng SSH (22) cho mọi dải IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 2. Mở cổng NodePort Kubernetes (30000 - 32767) cho mọi dải IP
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 3. Mở cổng HTTPS (443) cho mọi dải IP
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 4. Mở cổng Jenkins / Ứng dụng phụ (8080) cho mọi dải IP
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 5. Mở cổng HTTP (80) cho mọi dải IP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 6. Kubelet API (10250) - Chỉ cho phép các máy dùng chung SG này gọi lẫn nhau
  ingress {
    from_port = 10250
    to_port   = 10250
    protocol  = "tcp"
    self      = true
  }

  # 7. etcd server (2379 - 2380) - Chỉ cho phép các máy dùng chung SG này gọi lẫn nhau
  ingress {
    from_port = 2379
    to_port   = 2380
    protocol  = "tcp"
    self      = true
  }

  # 8. Kubernetes API Server (6443) - Chỉ cho phép các máy dùng chung SG này gọi lẫn nhau
  ingress {
    from_port = 6443
    to_port   = 6443
    protocol  = "tcp"
    self      = true
  }

  # 9. MỞ TOÀN BỘ TRAFFIC NỘI BỘ (ALL TRAFFIC) - Cho phép các máy cùng SG gọi nhau bất kể cổng/giao thức nào
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1" # -1 tương đương với "All" giao thức trên AWS (TCP, UDP, ICMP...)
    self      = true # Chỉ áp dụng nội bộ cho các tài nguyên gán chung Security Group này
  }

  # --- CHIỀU ĐI RA (OUTBOUND RULES / EGRESS) ---
  # Mặc định mở toang cho server đi ra ngoài Internet cập nhật hệ thống
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Thêm khối này vào cuối Security Group
  lifecycle {
    prevent_destroy = true
  }
}
