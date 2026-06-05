# AWS Kubernetes Platform — Terraform + Ansible

Tự động hóa toàn bộ quá trình dựng cụm Kubernetes trên AWS: từ cấp phát hạ tầng bằng Terraform đến cài đặt và cấu hình cluster bằng Ansible — không cần SSH thủ công vào từng máy.

![Terraform](https://img.shields.io/badge/Terraform-1.x-7B42BC?logo=terraform) ![Ansible](https://img.shields.io/badge/Ansible-2.x-EE0000?logo=ansible) ![Kubernetes](https://img.shields.io/badge/Kubernetes-kubeadm-326CE5?logo=kubernetes) ![AWS](https://img.shields.io/badge/AWS-EC2-FF9900?logo=amazonaws)

---

## Tổng quan

Thay vì vào AWS Console tạo từng EC2, rồi SSH vào từng máy cài Docker, cài kubeadm, init cluster, copy join token sang worker... dự án này rút gọn toàn bộ quy trình đó xuống còn một vài lệnh:

```bash
terraform apply          # cấp phát hạ tầng + tự sinh inventory.ini
ansible-playbook ...     # cài đặt và cấu hình toàn bộ cluster
```

Kết quả: cụm K8s 3 node (1 control plane + 2 worker) với đầy đủ Ingress, Metrics Server và monitoring stack — trong khoảng 10–20 phút.

---

## Kiến trúc

```
terraform apply
    │
    ├── VPC, Security Groups, EC2 x3
    │
    └── outputs.tf ──► inventory.ini (tự động, không cần hardcode IP)
                            │
                ┌───────────┴───────────┐
                │    4 Ansible Playbooks │
                └───────────────────────┘
                    │
                    ├── playbook1: Cài Kubernetes (kubeadm, kubelet, kubectl)
                    ├── playbook2: Init cluster + join worker nodes
                    ├── playbook3: Cài addons (Nginx Ingress, Metrics Server)
                    └── playbook4+5: Cài Docker + Nginx, setup monitoring
                                     (Prometheus, Grafana via kube-prometheus-stack)

Kết quả:
    control-plane (x1) ── worker-node-1 (x1)
                       └─ worker-node-2 (x1)
```

---

## Cấu trúc thư mục

```
├── main.tf                         # EC2 instances, VPC, security groups
├── variables.tf
├── outputs.tf
├── provider.tf
├── local_resources.tf              # Tự động sinh inventory.ini từ IP của EC2
│
└── ansible-lab/
    ├── inventory.ini               # Auto-generated bởi Terraform, không edit tay
    ├── playbook1_InstallK8s.yaml   # Cài kubeadm, kubelet, kubectl lên tất cả nodes
    ├── playbook2_k8s_init.yml      # Init control plane + join workers
    ├── playbook3_k8s_addons.yaml   # Nginx Ingress Controller, Metrics Server
    ├── playbook4_InstallDocker.yaml
    ├── playbook5_InstallNginx.yaml
    └── roles/
        ├── k8s_install/
        ├── role3-DockerInstall/
        └── setup-monitoring/       # kube-prometheus-stack
```

---

## Điểm thiết kế đáng chú ý

**Terraform tự sinh Ansible inventory**

Thay vì sau khi `terraform apply` phải vào xem IP rồi copy vào file inventory tay, `local_resources.tf` dùng data source để lấy IP của từng EC2 và ghi thẳng vào `inventory.ini`. Tear down rồi provision lại, inventory tự cập nhật — không lo nhầm IP.

**Tách playbook theo từng bước**

4 playbook độc lập thay vì một file lớn. Lý do thực tế: khi debug có thể re-run đúng bước bị lỗi mà không chạy lại toàn bộ. Ví dụ nếu playbook3 (addons) lỗi, không cần init lại cluster từ đầu.

**Dùng kubeadm thay vì EKS**

EKS đơn giản hơn nhưng che đi hết phần bootstrap. Dùng kubeadm để hiểu rõ control plane components, certificate generation, và join token flow — những thứ sẽ cần biết khi troubleshoot cluster thật.

---

## Yêu cầu

- AWS account + credentials đã cấu hình (`~/.aws/credentials`)
- SSH key tại `~/sshkeyaws` (hoặc đổi path trong `inventory.ini`)
- Terraform >= 1.0
- Ansible >= 2.12

---

## Cách chạy

```bash
# 1. Provision hạ tầng AWS và sinh inventory
terraform init
terraform apply
# Sau bước này inventory.ini được tạo tự động trong ansible-lab/

# 2. Cài Kubernetes lên tất cả nodes
ansible-playbook -i ansible-lab/inventory.ini ansible-lab/playbook1_InstallK8s.yaml

# 3. Init control plane và join workers
ansible-playbook -i ansible-lab/inventory.ini ansible-lab/playbook2_k8s_init.yml

# 4. Cài addons (Ingress, Metrics Server)
ansible-playbook -i ansible-lab/inventory.ini ansible-lab/playbook3_k8s_addons.yaml

# 5. Cài monitoring stack
ansible-playbook -i ansible-lab/inventory.ini ansible-lab/playbook4_InstallDocker.yaml
ansible-playbook -i ansible-lab/inventory.ini ansible-lab/playbook5_InstallNginx.yaml

# 6. Verify
kubectl get nodes
kubectl get pods -A
```

---

## Kết quả

Sau khi chạy xong:

```
NAME            STATUS   ROLES           AGE
control-plane   Ready    control-plane   ...
worker-node-1   Ready    <none>          ...
worker-node-2   Ready    <none>          ...
```

Grafana và Prometheus accessible qua Nginx Ingress. HPA hoạt động nhờ Metrics Server.

---

## Dọn dẹp

```bash
terraform destroy
```
