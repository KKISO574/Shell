#!/bin/sh
## 权限判定

function PermissionJudgment() {
    if [ $UID -ne 0 ]; then
        Output_Error "权限不足，请使用 Root 用户运行本脚本"
        exit
    fi
}
system(){
    if [ -f /etc/redhat-release ];then
        echo "系统检测通过"
    else
        echo "系统不是centos系列"
        exit

    fi


}
PermissionJudgment
system

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}

main_menu() {
red     "==============================================="
        echo "1) 初始化环境"
        echo "2) 安装docker版本"
        echo "3) 安装指定k8s版本"
        echo "0) 退出"
        echo "============================================"

read -p "请输入选项： " select
        case $select in
        1)
        set_base
        ;;
        2)
        docker
        ;;
        3)
        k8s
        ;;
        0)
        
        clear
        exit
        ;;

esac

}


function set_base(){
yum install -y ipset ipvsadm vim wget curl net-tools
# 关闭防火墙，PS：如果使用云服务器，还需要在云服务器的控制台中把防火墙关闭了或者允许所有端口。

systemctl stop firewalld
systemctl disable firewalld

# 永久关闭swap分区交换，kubeadm规定，一定要关闭
swapoff -a
sed -ri 's/.*swap.*/#&/' /etc/fstab
#关闭selinux
sed -i 's/enforcing/disabled/' /etc/selinux/config #重启后生效
# iptables配置
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
#内核预检
modprobe overlay
modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
# 将读取该文件中的参数设置，并将其应用到系统的当前运行状态中
sysctl -p /etc/sysctl.d/k8s.conf
# iptables生效参数
  sysctl --system
 main_menu
}

docker() {
echo "开始导入Docker镜像源"
#docker阿里源
yum install -y yum-utils 
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum list docker-ce --showduplicates | sort -r

read -p "输入你要安装的docker版本，例如24.0.7-1 ：" VERSION_STRING

sudo yum install docker-ce-$VERSION_STRING.el7 docker-ce-cli-$VERSION_STRING.el7 containerd.io docker-compose-plugin -y

if [ $? -eq 0 ]; then
    echo "docker安装成功"
else
    exit
    echo "安装失败检查输入的版本号"

fi

echo "变更镜像加速源以及cgroup"
sleep 1

cat <<EOF | sudo tee /etc/docker/daemon.json
{
	"registry-mirrors": [
        "http://hub-mirror.c.163.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://registry.docker-cn.com"
    ],
	"exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
systemctl daemon-reload && systemctl restart docker && systemctl enable docker && systemctl status docker 
docker info | grep -w "Cgroup Driver: systemd"
if [ $? -ne 0 ];then
echo "docker驱动不为systemd。请手动设置"

fi
main_menu
}

k8s() {

echo "导入k8s阿里源"
sleep 1
#k8s阿里云源
cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum list kubeadm --showduplicates | sort -r
read -p "选择你要安装的k8s版本：" k8s_ver
sudo yum install -y kubelet-$k8s_ver kubeadm-$k8s_ver kubectl-$k8s_ver --disableexcludes=kubernetes
kubeadm config images pull --kubernetes-version=$k8s_ver --image-repository registry.aliyuncs.com/google_containers
systemctl enable kubelet && systemctl start kubelet && systemctl status kubelet


main_menu
}
main_menu
lsmod | grep br_netfilter
echo "5秒后重启"
sleep 5
reboot
