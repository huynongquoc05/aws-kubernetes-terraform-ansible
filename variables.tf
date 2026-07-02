variable "aws_region" {
  type        = string
  description = "Khu vực chạy hạ tầng AWS"
  default     = "ap-southeast-1"
}

variable "instance_key_name" {
  type        = string
  description = "Tên cặp khóa SSH để truy cập vào máy chủ"
  default     = "singapore-devops-key"
}

variable "vpc_id" {
  type        = string
  description = "ID của VPC chứa cụm Cluster"
  default     = "vpc-0a439b872f293d716"
}

variable "cluster_instance_state" {
  type        = string
  description = "Trạng thái hoạt động của cả cụm máy chủ (running hoặc stopped)"
  default     = "running"
}

# --- BIẾN MỚI THÊM: HỆ ĐIỀU HÀNH & PHẦN CỨNG ---

variable "cluster_ami" {
  type        = string
  description = "AMI ID dùng chung cho cả cụm máy chủ (Ubuntu/CentOS...)"
  default     = "ami-02dd44faa40720bb8"
}

variable "master_instance_type" {
  type        = string
  description = "Cấu hình phần cứng cho nút Master (Control Plane)"
  default     = "t3.small"
}

variable "worker_instance_type" {
  type        = string
  description = "Cấu hình phần cứng mặc định cho các nút Worker"
  default     = "c7i-flex.large"
}

variable "worker2_instance_type" {
  type        = string
  description = "Cấu hình phần cứng riêng cho Worker Node 2 (loại to hơn)"
  default     = "c7i-flex.large"
}

variable "loadbalancer_instance_type" {
  type        = string
  description = "Cấu hình phần cứng riêng cho Worker Node 2 (loại to hơn)"
  default     = "t3.small"
}

# --- BIẾN MỚI THÊM: MẠNG (SUBNETS) ---

variable "subnet_zone_a" {
  type        = string
  description = "Subnet thuộc Availability Zone A hoặc B tùy thiết kế"
  default     = "subnet-0fe7122a8383cbe0a"
}

variable "subnet_zone_b" {
  type        = string
  description = "Subnet thứ hai để chia tải hoặc chạy song song"
  default     = "subnet-089294fb142265bd1"
}

# --- BIẾN MỚI THÊM: Ổ CỨNG (STORAGE) ---

variable "root_volume_size" {
  type        = number
  description = "Dung lượng ổ đĩa mặc định (GB)"
  default     = 8
}

variable "root_volume_type" {
  type        = string
  description = "Loại ổ đĩa (gp2, gp3, io1...)"
  default     = "gp3"
}


variable "nlb-port" {
  type = map(object({
    port         = number  # Cổng mặt tiền của NLB đón khách
    backend_port = number  # Cổng hậu trường chạy trên EC2/Worker
    protocol     = string
  }))
  default = {
    "http" = {
      port         = 80
      backend_port = 32080 # Phân phối về cổng NodePort này
      protocol     = "TCP"
    },
    "https" = {
      port         = 443
      backend_port = 30443 # Phân phối về cổng NodePort HTTPS
      protocol     = "TCP"
    },
    "kube_api" = {
      port         = 6443
      backend_port = 6443  # Giữ nguyên 6443 cho API Server
      protocol     = "TCP"
    }
  }
}