# =====================================================================
# KHỐI RESOURCES - CỤM MÁY CHỦ KUBERNETES
# =====================================================================

# 1. Máy chủ Control Plane (Master Node)
resource "aws_instance" "control_plane" {
  for_each = {
    "node1"={subnet= var.subnet_zone_a, name= "CONTROL-PLANE-1"},
    "node2"={subnet= var.subnet_zone_a, name= "CONTROL-PLANE-2"},
    "node3"={subnet= var.subnet_zone_b, name= "CONTROL-PLANE-3"}
  }

  ami                    = var.cluster_ami
  instance_type          = var.master_instance_type
  subnet_id              = each.value.subnet
  key_name               = var.instance_key_name
  vpc_security_group_ids = [aws_security_group.cluster_sec_g.id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
  }

  tags = {
    Name = each.value.name
  }

  lifecycle {
    prevent_destroy = false
  }
}

# 2. Quản lý toàn bộ Máy chủ Worker Node tập trung
resource "aws_instance" "worker_node" {
  for_each = {
    "worker1" = {
      subnet        = var.subnet_zone_a
      name          = "WORKER-1"
      instance_type = var.worker2_instance_type # Giữ nguyên cấu hình của bạn
      volume_size   = 15
    },
    "worker2" = {
      subnet        = var.subnet_zone_b        # Nằm ở subnet khác biệt
      name          = "WORKER-2"
      instance_type = var.worker2_instance_type # Nếu sau này muốn đổi thành c7i-flex, bạn chỉ cần thay giá trị này hoặc var mới
      volume_size   = 15
    },
    "worker3" = {
      subnet        = var.subnet_zone_a        # Giả sử bạn muốn tạo thêm con thứ 3 cho đủ bộ
      name          = "WORKER-33"
      instance_type = var.worker2_instance_type
      volume_size   = 15
    }
  }

  ami                    = var.cluster_ami
  instance_type          = each.value.instance_type # Tùy biến theo từng node
  subnet_id              = each.value.subnet        # Tùy biến theo từng node
  key_name               = var.instance_key_name
  vpc_security_group_ids = [aws_security_group.cluster_sec_g.id]

  root_block_device {
    volume_size = each.value.volume_size
    volume_type = var.root_volume_type
  }

  tags = {
    Name = each.value.name
  }

  lifecycle {
    prevent_destroy = false
  }
}

# # Loadbalancer
# resource "aws_instance" "ec2_loadbalancer" {
#   ami = var.cluster_ami
#   instance_type = var.loadbalancer_instance_type
#   subnet_id = var.subnet_zone_a
#   key_name = var.instance_key_name
#   vpc_security_group_ids = [aws_security_group.cluster_sec_g.id]
#
#   tags = {
#     Name = "LOAD_BALANCER"
#   }
#    root_block_device {
#     volume_size = 8
#     volume_type = var.root_volume_type
#    }
# }

# =====================================================================
# KHỐI TRẠNG THÁI - ĐIỀU KHIỂN BẬT/TẮT TẬP TRUNG
# =====================================================================

# 1. Điều khiển trạng thái cho toàn bộ cụm Control Plane
resource "aws_ec2_instance_state" "control_plane_state" {
  for_each    = aws_instance.control_plane  # Lặp trực tiếp qua Map các máy Control Plane đã tạo
  instance_id = each.value.id
  state       = var.cluster_instance_state
}

# 2. Điều khiển trạng thái cho toàn bộ cụm Worker Node
resource "aws_ec2_instance_state" "worker_node_state" {
  for_each    = aws_instance.worker_node    # Lặp trực tiếp qua Map các máy Worker Node đã tạo
  instance_id = each.value.id
  state       = var.cluster_instance_state
}

# resource "aws_ec2_instance_state" "loadbalancer_state" {
#   instance_id = aws_instance.ec2_loadbalancer.id
#     state       = var.cluster_instance_state
# }

# =====================================================================
# KHỐI THÁM TỬ - LẤY IP SAU KHI MÁY ĐÃ RUNNING
# =====================================================================

# 3. Dò IP trực tiếp cho toàn bộ máy Control Plane
data "aws_instance" "control_plane_live" {
  for_each    = aws_instance.control_plane
  instance_id = each.value.id

  # Chốt chặn: Máy nào chạy xong trạng thái máy đó thì thám tử của máy đó mới đi lùng IP
  depends_on  = [aws_ec2_instance_state.control_plane_state]
}

# 4. Dò IP trực tiếp cho toàn bộ máy Worker Node
data "aws_instance" "worker_node_live" {
  for_each    = aws_instance.worker_node
  instance_id = each.value.id

  # Chốt chặn tương tự cho phía Worker Node
  depends_on  = [aws_ec2_instance_state.worker_node_state]
}

# data "aws_instance" "loadbalancer_live"{
#   instance_id = aws_instance.ec2_loadbalancer.id
#   depends_on = [aws_ec2_instance_state.loadbalancer_state]
# }