
# =====================================================================
# 3. KHỐI securityG (ĐÃ SỬA RÀO CẢN NLB)
# =====================================================================
resource "aws_security_group" "cluster_sec_g" {
  name        = "launch-wizard-2"
  description = "launch-wizard-2 created 2026-05-29T09:12:09.997Z"
  vpc_id      = var.vpc_id

  # --- CÁC QUY TẮC CŨ GIỮ NGUYÊN (SSH, NodePort, HTTP, HTTPS, Jenkins, All Traffic nội bộ...) ---
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # --- THAY ĐỔI QUAN TRỌNG: MỞ TOANG CỔNG 6443 ĐỂ THÔNG MẠCH VỚI NLB ---
  # Thay vì để "self = true", bạn nâng cấp lên mở rộng dải IP để NLB check health & client kết nối được
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # An toàn hơn nếu bạn điền dải CIDR của VPC của bạn (ví dụ "172.31.0.0/16") thay vì 0.0.0.0/0 nếu NLB là internal.
  }

  # --- CÁC KHỐI NỘI BỘ KHÁC GIỮ NGUYÊN ---
  ingress {
    from_port = 10250
    to_port   = 10250
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 2379
    to_port   = 2380
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    prevent_destroy = false # Chuyển thành false nếu bạn cần đập đi xây lại hạ tầng liên tục trong lúc lab
  }
}


# =====================================================================
# 3. KHỐI Load_Balancer
# =====================================================================

resource "aws_lb" "my_lb01" {
  name = "main-lb"
  internal           = false
  load_balancer_type = "network"

  subnets = [
  var.subnet_zone_b,var.subnet_zone_a]

  enable_deletion_protection = false

  tags = {
    Name = "main-lb"
    Environment = "production"
  }
}

#Target gropp cho k8s control plane

# Target group cho k8s control plane & workers
resource "aws_lb_target_group" "k8s-api-tg" {
  for_each    = var.nlb-port

  # DÙNG HÀM REPLACE: tự động biến "kube_api" thành "kube-api" để AWS không bắt lỗi
  name        = "tg-${replace(each.key, "_", "-")}-${each.value.port}"
  port        = each.value.backend_port # "http" = 80, "https" = 443, "kube_api" = 6443
  vpc_id      = var.vpc_id
  target_type = "instance"
  # BỔ SUNG DÒNG NÀY: Khai báo protocol cho Target Group (Sửa Lỗi số 1)
  protocol    = each.value.protocol
  health_check {
    interval            = 10
    port                = each.value.backend_port
    protocol            = each.value.protocol
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener cho k8s control plane
resource "aws_lb_listener" "k8s-api-listener" {
    for_each = var.nlb-port
    load_balancer_arn = aws_lb.my_lb01.arn
    port = each.value.port
    protocol = each.value.protocol

    default_action {
      type = "forward"
        target_group_arn = aws_lb_target_group.k8s-api-tg[each.key].arn
    }
}

# đính kèm cho control plane
resource "aws_lb_target_group_attachment" "control_plane_attachment" {
  for_each = aws_instance.control_plane
  target_group_arn = aws_lb_target_group.k8s-api-tg["kube_api"].arn
  target_id        = each.value.id
  port = var.nlb-port.kube_api.port
}

# # đính kèm cho worker node
# resource "aws_lb_target_group_attachment" "worker_node_attachment" {
#   for_each = aws_instance.worker_node
#   target_group_arn = aws_lb_target_group.k8s-api-tg["kube_api"].arn
#   target_id        = each.value.id
#   port = var.nlb-port.kube_api.port
# }

# đính kèm cho worker node 80
resource "aws_lb_target_group_attachment" "worker_node_attachment_80" {
  for_each = aws_instance.worker_node
  target_group_arn = aws_lb_target_group.k8s-api-tg["http"].arn
  target_id        = each.value.id
  port = 32080

}


