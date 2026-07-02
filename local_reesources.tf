# =====================================================================
# TỰ ĐỘNG TẠO FILE INVENTORY CHO ANSIBLE (LẤY IP TỪ DATA SOURCE)
# =====================================================================

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible-lab/inventory.ini"

  content = <<EOT
[control_plane]
%{ for key, host in data.aws_instance.control_plane_live ~}
${key} ansible_host=${host.public_ip} private_ip=${host.private_ip}
%{ endfor ~}

[workers]
%{ for key, host in data.aws_instance.worker_node_live ~}
${key} ansible_host=${host.public_ip} private_ip=${host.private_ip}
%{ endfor ~}

[k8s_cluster:children]
control_plane
workers

[loadbalancer]
loadbalancer_api ansible_host=${aws_lb.my_lb01.dns_name}
[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/sshkeyaws
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3
EOT

  # Đảm bảo file local chỉ ghi khi toàn bộ các thám tử đã thu thập đủ thông tin IP
  depends_on = [
    data.aws_instance.control_plane_live,
    data.aws_instance.worker_node_live,
#     data.aws_instance.loadbalancer_live
  ]
}