# Guia de Configuração do Kubernetes em VM (Português)

## 1. Definir o hostname

**Master:**
```
sudo hostnamectl set-hostname "k8smaster" && exec bash
```
Explicação: Define o nome do host do servidor master para facilitar a identificação na rede.

**Node 01:**
```
sudo hostnamectl set-hostname "k8sworker1" && exec bash
```
Explicação: Define o nome do host do primeiro nó worker.

**Node 02:**
```
sudo hostnamectl set-hostname "k8sworker2" && exec bash
```
Explicação: Define o nome do host do segundo nó worker.

## 2. Configurar /etc/hosts
Adicione as linhas abaixo em todos os servidores:
```
10.0.0.4    k8smaster
10.0.0.5    k8sworker1
10.0.0.6    k8sworker2
```
Explicação: Permite que os servidores se comuniquem usando nomes amigáveis.

## 3. Desabilitar Swap e ajustar parâmetros do kernel
```
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```
Explicação: O Kubernetes exige que o swap esteja desabilitado para funcionar corretamente.

## 4. Carregar módulos necessários
```
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
```
Explicação: Carrega módulos do kernel necessários para redes de containers.

## 5. Configurar parâmetros do kernel
```
sudo tee /etc/sysctl.d/kubernetes.conf <<EOT
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOT
sudo sysctl --system
```
Explicação: Ajusta parâmetros para permitir o roteamento e filtragem de pacotes.

## 6. Instalar Docker e Containerd
```
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io
```
Explicação: Instala o runtime de containers necessário para o Kubernetes.

## 7. Configurar containerd para usar systemd como cgroup
```
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
```
Explicação: Garante compatibilidade do containerd com o Kubernetes.

## 8. Reiniciar e habilitar containerd
```
sudo systemctl restart containerd
sudo systemctl enable containerd
```
Explicação: Aplica as configurações e garante que o serviço inicie automaticamente.

## 9. Adicionar repositório do Kubernetes
```
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```
Explicação: Adiciona o repositório oficial para instalar os componentes do Kubernetes.

## 10. Instalar Kubectl, Kubeadm e Kubelet
```
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```
Explicação: Instala as ferramentas principais do Kubernetes e impede atualizações automáticas.

## 11. Inicializar o cluster (apenas no master)
```
sudo kubeadm init --control-plane-endpoint=k8smaster
```
Explicação: Inicializa o cluster Kubernetes no servidor master.

## 12. Configurar acesso ao cluster (apenas no master)
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
Explicação: Permite que o usuário administre o cluster usando o kubectl.

## 13. Verificar informações do cluster
```
kubectl cluster-info
kubectl get nodes
```
Explicação: Exibe informações e status dos nós do cluster.

## 14. Instalar o plugin de rede Calico (apenas no master)
```
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml
kubectl get pods -n kube-system
kubectl get nodes
```
Explicação: Instala o Calico para gerenciar a rede dos containers.

## 15. Adicionar os workers ao cluster
Pegue o comando `kubeadm join` gerado pelo master e execute nos nodes workers.

## 16. Testar o cluster
```
kubectl create ns demo-app
kubectl create deployment nginx-app --image nginx --replicas 2 --namespace demo-app
kubectl get deployment -n demo-app
kubectl get pods -n demo-app
kubectl expose deployment nginx-app -n demo-app --type NodePort --port 80
kubectl get svc -n demo-app
kubectl expose deployment php-app-deployment --type NodePort --port 80
kubectl get pods --all-namespaces -o wide
```
Explicação: Cria um namespace, um deployment do nginx, expõe o serviço e verifica o funcionamento do cluster.