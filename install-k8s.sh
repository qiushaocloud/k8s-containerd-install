#!/bin/bash

K8S_VERSION='1.26.0'
echo "K8S_VERSION: $K8S_VERSION"

OS_STR=`cat /etc/issue | grep -v grep | grep -E "Ubuntu|Centos" | awk -F ' ' '{print $1}'`
echo "OS_STR: $OS_STR"
echo `cat /etc/issue`

if [ "$OS_STR" == "Ubuntu" ]; then
  echo "this is Ubuntu OS"
elif [ "$OS_STR" == "Centos" ]; then
  echo "this is Centos OS"
else
  echo "this is void OS, OS_STR: $OS_STR"
  exit 1
fi


if [ "$OS_STR" == "Ubuntu" ]; then

echo "===================== ubuntu install k8s start ========================="

echo 修改内核参数
sed -i "/net.ipv4.ip_nonlocal_bind = 1/d" /etc/sysctl.conf
cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_nonlocal_bind = 1
EOF

echo 查看内核参数
sysctl -p

echo 安装 ufw
apt update
apt install -y ufw

echo 临时关闭swap
swapoff -a
echo 永久关闭swap
sed -i '/swap/s/^/#/' /etc/fstab

echo 禁用默认配置的iptables防火墙服务
ufw diable
ufw status

echo 加载模块
modprobe overlay
modprobe br_netfilter

echo 开机加载
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

echo 设置所需的sysctl参数，参数在重新启动后保持不变
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

echo 应用sysctl参数而不重新启动
sysctl --system

echo 开启ipvs支持
apt install -y ipvsadm ipset
echo ipvs临时生效
for i in $(ls /lib/modules/$(uname -r)/kernel/net/netfilter/ipvs|grep -o "^[^.]*");do echo $i; /sbin/modinfo -F filename $i >/dev/null 2>&1 && /sbin/modprobe $i; done

echo ipvs永久生效
if [ "`grep "ip_vs" /etc/modules`" != "" ]; then
  ls /lib/modules/$(uname -r)/kernel/net/netfilter/ipvs|grep -o "^[^.]*" >> /etc/modules
fi

echo 配置containerd

if [ ! -f "cri-containerd-cni-1.6.16-linux-amd64.tar.gz" ]; then
  echo "start download cri-containerd-cni-1.6.16-linux-amd64.tar.gz from github"
  wget -t 1 https://github.com/containerd/containerd/releases/download/v1.6.16/cri-containerd-cni-1.6.16-linux-amd64.tar.gz -O cri-containerd-cni-1.6.16-linux-amd64.tar.gz
  if [ `ls -l | grep "cri-containerd-cni-1.6.16-linux-amd64.tar.gz" | grep -v grep | awk -F " " '{print $5}'` -gt 120847122 ]; then
    echo 'download finsh from github'
  else
    echo "download failure from github, need wget https://www.qiushaocloud.top/common-static/k8s-files/cri-containerd-cni-1.6.16-linux-amd64.tar.gz"
    wget -t 3 https://www.qiushaocloud.top/common-static/k8s-files/cri-containerd-cni-1.6.16-linux-amd64.tar.gz -O cri-containerd-cni-1.6.16-linux-amd64.tar.gz

    if [ `ls -l | grep "cri-containerd-cni-1.6.16-linux-amd64.tar.gz" | grep -v grep | awk -F " " '{print $5}'` -gt 120847122 ]; then
      echo "download cri-containerd-cni-1.6.16-linux-amd64.tar.gz file success"
    else
      echo "download cri-containerd-cni-1.6.16-linux-amd64.tar.gz file failure, need remove file, ls -l:"`ls -l`
      rm -rf cri-containerd-cni-1.6.16-linux-amd64.tar.gz
    fi
  fi

  echo "file download finsh, ls -l:"`ls -l`
else
  echo "exit cri-containerd-cni-1.6.16-linux-amd64.tar.gz file"
fi

echo cri-containerd-cni-1.6.16-linux-amd64.tar.gz 解压到根目录
tar -xvf cri-containerd-cni-1.6.16-linux-amd64.tar.gz -C /

echo 修改containerd的配置，将sandox_image镜像源设置为阿里云google_containers镜像源
mkdir /etc/containerd/
echo 产生containerd默认配置文件
containerd config default > /etc/containerd/config.toml

echo 改变sandbox_image
grep sandbox_image /etc/containerd/config.toml
#sed -i "s#k8s.gcr.io/pause:3.5#registry.aliyuncs.com/google_containers/pause:3.9#g" /etc/containerd/config.toml
sed -i "s#k8s.gcr.io/pause#registry.aliyuncs.com/google_containers/pause#g" /etc/containerd/config.toml
#sed -i "s#registry.k8s.io/pause:3.6#registry.aliyuncs.com/google_containers/pause:3.9#g" /etc/containerd/config.toml
sed -i "s#registry.k8s.io/pause#registry.aliyuncs.com/google_containers/pause#g" /etc/containerd/config.toml

echo 镜像加速
sed -i '/\[plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"docker.io\"\]/d' /etc/containerd/config.toml
sed -i '/endpoint = \[\"https:\/\/registry.aliyuncs.com\"\]/d' /etc/containerd/config.toml
sed -i 's#\[plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors\]#\[plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors\]\n        \[plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"docker.io\"\]\n          endpoint = \[\"https:\/\/registry.aliyuncs.com\"\]#' /etc/containerd/config.toml

echo 配置containerd cgroup驱动程序systemd
sed -i 's#SystemdCgroup = false#SystemdCgroup = true#g' /etc/containerd/config.toml
grep SystemdCgroup /etc/containerd/config.toml

echo 重新daemon-reload，启用containerd
systemctl daemon-reload
#systemctl status containerd &
systemctl enable --now containerd
systemctl is-active containerd
systemctl restart containerd
#systemctl status containerd &

echo 安装CNI插件工具
tar -xvf cni-plugins-linux-amd64-v1.2.0.tgz -C /opt/cni/bin

echo "ctr version: `ctr version`"
echo "crictl version: `crictl version`"

echo "------------------ add k8s source list ---------------------"
apt-get update && apt-get install -y apt-transport-https ca-certificates curl

curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 

cat <<EOF >/etc/apt/sources.list.d/kubernetes-install.list
deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main
EOF

apt-get update

echo 查看版本
apt-cache madison kubeadm|head
echo 安装指定版本, K8S_VERSION: $K8S_VERSION
apt install -y kubeadm=$K8S_VERSION-00 kubelet=$K8S_VERSION-00 kubectl=$K8S_VERSION-00
#echo 安装最新版本
#apt install -y kubeadm kubelet kubectl

systemctl daemon-reload && systemctl restart kubelet

echo "===================== ubuntu install k8s end ========================="

fi

if [ "$OS_STR" == "Centos" ]; then

echo "===================== centos install k8s start ========================="

echo 安装和配置的先决条件
cat <<EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

echo 开启内核参数
sed -i "/net.ipv4.ip_forward = 1/d" /etc/sysctl.conf
sed -i "/net.bridge.bridge-nf-call-iptables = 1/d" /etc/sysctl.conf
sed -i "/net.bridge.bridge-nf-call-ip6tables = 1/d" /etc/sysctl.conf
cat >> /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl -p

echo 设置必需的 sysctl 参数，这些参数在重新启动后仍然存在。
cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

echo 应用 sysctl 参数而无需重新启动
sysctl --system

echo 关闭交换空间
swapoff -a
sed -ri 's/.*swap.*/#&/' /etc/fstab

echo 关闭防火墙
systemctl stop firewalld && systemctl disable  firewalld
systemctl stop NetworkManager && systemctl disable  NetworkManager

echo 禁用 SELinux
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

echo 应用sysctl参数而不重新启动
sysctl --udystem

echo 开启ipvs支持
yum install -y ipvsadm ipset
# 临时生效
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4

# 永久生效
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF


echo 系统有没有 libseccomp 软件包
libseccomp_str=`rpm -qa | grep libseccomp`
echo libseccomp_str=$libseccomp_str
if [ "$libseccomp_str=" != "" ]; then
  echo echo 卸载原来的, libseccomp_str=$libseccomp_str
  rpm -e libseccomp-2.3.1-4.el7.x86_64 --nodeps
fi
echo install libseccomp-2.5.1-1.el8.x86_64.rpm
rpm -ivh libseccomp-2.5.1-1.el8.x86_64.rpm
rpm -qa | grep libseccomp

echo 配置containerd

if [ ! -f "cri-containerd-cni-1.6.16-linux-amd64.tar.gz" ]; then
  echo "start download cri-containerd-cni-1.6.16-linux-amd64.tar.gz from github"
  wget https://github.com/containerd/containerd/releases/download/v1.6.16/cri-containerd-cni-1.6.16-linux-amd64.tar.gz -O cri-containerd-cni-1.6.16-linux-amd64.tar.gz
  if [ `ls -l | grep "cri-containerd-cni-1.6.16-linux-amd64.tar.gz" | grep -v grep | awk -F " " '{print $5}'` -gt 120847122 ]; then
    echo 'download finsh from github'
  else
    echo "download failure from github, need wget https://www.qiushaocloud.top/common-static/k8s-files/cri-containerd-cni-1.6.16-linux-amd64.tar.gz"
    wget https://www.qiushaocloud.top/common-static/k8s-files/cri-containerd-cni-1.6.16-linux-amd64.tar.gz -O cri-containerd-cni-1.6.16-linux-amd64.tar.gz

    if [ `ls -l | grep "cri-containerd-cni-1.6.16-linux-amd64.tar.gz" | grep -v grep | awk -F " " '{print $5}'` -gt 120847122 ]; then
      echo "download cri-containerd-cni-1.6.16-linux-amd64.tar.gz file success"
    else
      echo "download cri-containerd-cni-1.6.16-linux-amd64.tar.gz file failure, need remove file, ls -l:"`ls -l`
      rm -rf cri-containerd-cni-1.6.16-linux-amd64.tar.gz
    fi
  fi

  echo "file download finsh, ls -l:"`ls -l`
else
  echo "exit cri-containerd-cni-1.6.16-linux-amd64.tar.gz file"
fi

echo cri-containerd-cni-1.6.16-linux-amd64.tar.gz 解压到根目录
tar -xvf cri-containerd-cni-1.6.16-linux-amd64.tar.gz -C /

echo 修改containerd的配置，将sandox_image镜像源设置为阿里云google_containers镜像源
mkdir /etc/containerd/
echo 产生containerd默认配置文件
containerd config default > /etc/containerd/config.toml

echo 改变sandbox_image
grep sandbox_image /etc/containerd/config.toml
#sed -i "s#k8s.gcr.io/pause:3.5#registry.aliyuncs.com/google_containers/pause:3.9#g" /etc/containerd/config.toml
sed -i "s#k8s.gcr.io/pause#registry.aliyuncs.com/google_containers/pause#g" /etc/containerd/config.toml
#sed -i "s#registry.k8s.io/pause:3.6#registry.aliyuncs.com/google_containers/pause:3.9#g" /etc/containerd/config.toml
sed -i "s#registry.k8s.io/pause#registry.aliyuncs.com/google_containers/pause#g" /etc/containerd/config.toml


echo 镜像加速
sed -i '/\[plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"docker.io\"\]/d' /etc/containerd/config.toml
sed -i '/endpoint = \[\"https:\/\/registry.aliyuncs.com\"\]/d' /etc/containerd/config.toml
sed -i 's#\[plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors\]#\[plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors\]\n        \[plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"docker.io\"\]\n          endpoint = \[\"https:\/\/registry.aliyuncs.com\"\]#' /etc/containerd/config.toml

echo 配置containerd cgroup驱动程序systemd
sed -i 's#SystemdCgroup = false#SystemdCgroup = true#g' /etc/containerd/config.toml
grep SystemdCgroup /etc/containerd/config.toml

echo 重新daemon-reload，启用containerd
systemctl daemon-reload
#systemctl status containerd &
systemctl enable --now containerd
systemctl is-active containerd
systemctl restart containerd
#systemctl status containerd &

echo 安装CNI插件工具
tar -xvf cni-plugins-linux-amd64-v1.2.0.tgz -C /opt/cni/bin

echo "ctr version: `ctr version`"
echo "crictl version: `crictl version`"


echo 安装 kubeadm、kubelet 和 kubectl
cat <<EOF | tee /etc/yum.repos.d/kubernetes-install.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
        http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# --disableexcludes 禁掉除了kubernetes之外的别的仓库
# 由于官网未开放同步方式, 替换成阿里源后可能会有索引 gpg 检查失败的情况, 这时请带上`--nogpgcheck`选项安装
echo 指定安装版本,K8S_VERSION: $K8S_VERSION
yum update
yum install -y kubelet-$K8S_VERSION kubeadm-$K8S_VERSION kubectl-$K8S_VERSION --disableexcludes=kubernetes --nogpgcheck

systemctl daemon-reload && systemctl restart kubelet

echo "===================== centos install k8s end ========================="

fi
