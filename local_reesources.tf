# =====================================================================
# TỰ ĐỘNG TẠO FILE INVENTORY CHO ANSIBLE (LẤY IP TỪ DATA SOURCE)
# =====================================================================

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible-lab/inventory.ini"

  content = <<EOT
[control_plane]
control_plane ansible_host=${data.aws_instance.control_plane_live.public_ip} private_ip=${data.aws_instance.control_plane_live.private_ip}

[workers]
worker1 ansible_host=${data.aws_instance.worker_node1_live.public_ip} private_ip=${data.aws_instance.worker_node1_live.private_ip}
worker2 ansible_host=${data.aws_instance.worker_node2_live.public_ip} private_ip=${data.aws_instance.worker_node2_live.private_ip}

[k8s_cluster:children]
control_plane
workers

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/sshkeyaws
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3
EOT

  # Lúc này local_file chỉ cần phụ thuộc vào dữ liệu của 3 con thám tử là tự động chuẩn bài
  depends_on = [
    data.aws_instance.control_plane_live,
    data.aws_instance.worker_node1_live,
    data.aws_instance.worker_node2_live
  ]
}