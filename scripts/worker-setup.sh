#!/bin/bash
# Script para configurar o nó worker do Kubernetes

# Definir hostname (ajuste conforme o nó)
# Exemplo para worker1:
sudo hostnamectl set-hostname "k8sworker1" && exec bash
# Exemplo para worker2:
# sudo hostnamectl set-hostname "k8sworker2" && exec bash

# Configurar /etc/hosts
cat <<EOF | sudo tee -a /etc/hosts
10.0.0.4    k8smaster
10.0.0.5    k8sworker1
10.0.0.6    k8sworker2
EOF

# Desabilitar swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Carregar módulos
sudo tee /etc/modules-load.d/containerd.conf <<EOM
overlay
br_netfilter
EOM
sudo modprobe overlay
sudo modprobe br_netfilter

# Parâmetros do kernel
sudo tee /etc/sysctl.d/kubernetes.conf <<EOT
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOT
sudo sysctl --system

# Instalar containerd
sudo apt update
sudo apt install -y containerd.io

# Configurar containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# Adicionar repositório Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Instalar kubectl, kubeadm, kubelet
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Para ingressar no cluster, execute o comando kubeadm join fornecido pelo master
# Exemplo:
# sudo kubeadm join k8smaster:6443 --token <token> --discovery-token-ca-cert-hash <hash>
