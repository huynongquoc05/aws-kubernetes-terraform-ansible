# =====================================================================
# OUTPUT TẬP TRUNG CHO CỦM CONTROL PLANE & WORKER NODES
# =====================================================================

output "control_plane_ips" {
  description = "Bản đồ IP (Public & Private) của các máy Control Plane"
  value = {
    for key, host in data.aws_instance.control_plane_live :
    key => {
      public_ip  = host.public_ip
      private_ip = host.private_ip
    }
  }
}

output "worker_node_ips" {
  description = "Bản đồ IP (Public & Private) của các máy Worker Node"
  value = {
    for key, host in data.aws_instance.worker_node_live :
    key => {
      public_ip  = host.public_ip
      private_ip = host.private_ip
    }
  }
}