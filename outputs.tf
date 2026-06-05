output "master_public_ip" {
  value       = data.aws_instance.control_plane_live.public_ip
  description = "Public IP của Control Plane"
}

output "worker1_public_ip" {
  value       = data.aws_instance.worker_node1_live.public_ip
  description = "Public IP của Worker 1"
}

output "worker2_public_ip" {
  value       = data.aws_instance.worker_node2_live.public_ip
  description = "Public IP của Worker 2"
}

output "master_private_ip" {
  value       = aws_instance.control_plane.private_ip
  description = "Private IP của Control Plane"
}

output "worker1_private_ip" {
  value       = aws_instance.worker_node1_ec2.private_ip
  description = "Private IP của Worker 1"
}

output "worker2_private_ip" {
  value       = aws_instance.worker_node2_ec2.private_ip
  description = "Private IP của Worker 2"
}