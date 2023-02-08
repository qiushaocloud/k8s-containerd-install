#!/bin/bash

set -a
source .env
set +a

bash getLocalIP.sh

LOCAL_IP=`cat /tmp/getLocalIpResult`
MY_HOSTNAME=`hostname`

echo "LOCAL_IP=$LOCAL_IP"
echo "MY_HOSTNAME=$MY_HOSTNAME"

apiserverAdvertiseAddress=$LOCAL_IP
apiserverBindPort=$APISERVER_BIND_PORT
controlPlaneEndpoint=$CONTROL_PLANE_ENDPOINT
k8sToken=$K8S_TOKEN

echo "cp files"
cp kubeadm-config.yml.tpl kubeadm-config.yml
cp calico.yaml.tpl calico.yaml

echo "set var to kubeadm-config.yml"
sed -i "s/<ADVERTISE_ADDRESS>/$apiserverAdvertiseAddress/g" kubeadm-config.yml
sed -i "s/<BIND_PORT>/$apiserverBindPort/g" kubeadm-config.yml
sed -i "s/<MY_HOSTNAME>/$MY_HOSTNAME/g" kubeadm-config.yml

if [ "$INTERFACE_NAME" != "" ]; then
    sed -i "s/<INTERFACE_NAME>/$INTERFACE_NAME/g" calico.yaml
else
    sed -i "/指定网卡/d" calico.yaml
    sed -i "/<IP_AUTODETECTION_METHOD>/d" calico.yaml
    sed -i "/<INTERFACE_NAME>/d" calico.yaml
fi

if [ "$controlPlaneEndpoint" != "" ]; then
    sed -i "s/<CONTROL_PLANE_ENDPOINT>/$controlPlaneEndpoint/g" kubeadm-config.yml

    if [ "$k8sToken" != "" ]; then
        sed -i "s/<TOKEN>/$k8sToken/g" kubeadm-config.yml
        sed -i "s/ttl: 24h0m0s/ttl: 0/g" kubeadm-config.yml
        #kubeadm init --kubernetes-version v1.26.0 --image-repository registry.aliyuncs.com/google_containers --apiserver-advertise-address=$apiserverAdvertiseAddress --apiserver-bind-port=$apiserverBindPort --pod-network-cidr=10.244.0.0/16 --service-cidr=10.1.0.0/16 --upload-certs --control-plane-endpoint=$controlPlaneEndpoint --token=$token --token-ttl=0 --cri-socket unix:///run/containerd/containerd.sock
    else
        sed -i "/指定token/d" kubeadm-config.yml
        sed -i "/<TOKEN>/d" kubeadm-config.yml
        sed -i "/ttl: 24h0m0s/d" kubeadm-config.yml
        #kubeadm init --kubernetes-version v1.26.0 --image-repository registry.aliyuncs.com/google_containers --apiserver-advertise-address=$apiserverAdvertiseAddress --apiserver-bind-port=$apiserverBindPort --pod-network-cidr=10.244.0.0/16 --service-cidr=10.1.0.0/16 --upload-certs --control-plane-endpoint=$controlPlaneEndpoint --cri-socket unix:///run/containerd/containerd.sock
    fi
else
    sed -i "/<CONTROL_PLANE_ENDPOINT>/d" kubeadm-config.yml

    if [ "$k8sToken" != "" ]; then
        sed -i "s/<TOKEN>/$k8sToken/g" kubeadm-config.yml
        sed -i "s/ttl: 24h0m0s/ttl: 0/g" kubeadm-config.yml
        #kubeadm init --kubernetes-version v1.26.0 --image-repository registry.aliyuncs.com/google_containers --pod-network-cidr=10.244.0.0/16 --service-cidr=10.1.0.0/16 --apiserver-advertise-address=$apiserverAdvertiseAddress --apiserver-bind-port=$apiserverBindPort --upload-certs --token=$token --token-ttl=0 --cri-socket unix:///run/containerd/containerd.sock
    else
        sed -i "/指定token/d" kubeadm-config.yml
        sed -i "/<TOKEN>/d" kubeadm-config.yml
        sed -i "/ttl: 24h0m0s/d" kubeadm-config.yml
        #kubeadm init --kubernetes-version v1.26.0 --image-repository registry.aliyuncs.com/google_containers --pod-network-cidr=10.244.0.0/16 --service-cidr=10.1.0.0/16 --apiserver-advertise-address=$apiserverAdvertiseAddress --apiserver-bind-port=$apiserverBindPort --upload-certs --cri-socket unix:///run/containerd/containerd.sock
    fi
fi

kubeadm init --config=$PWD/kubeadm-config.yml --upload-certs | tee kubeadm-init.log

CHECK_INIT_OK_STR=`grep "kubeadm join " kubeadm-init.log`
if [ "$CHECK_INIT_OK_STR" != "" ]; then
    echo "kubeadm init success"
    
    echo "cp files to $HOME/.kube"
    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config
    export KUBECONFIG=/etc/kubernetes/admin.conf
    sed -i '/export KUBECONFIG=/d' $HOME/.bashrc
    echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> $HOME/.bashrc
    source $HOME/.bashrc

    echo "set service-node-port-range=1-65535 to /etc/kubernetes/manifests/kube-apiserver.yaml"
    sed -i "/- --service-node-port-range=1-65535/d" /etc/kubernetes/manifests/kube-apiserver.yaml
    sed -i "s#- kube-apiserver#- kube-apiserver\n    - --service-node-port-range=1-65535#" /etc/kubernetes/manifests/kube-apiserver.yaml

    if [ "$IS_USE_FLANNEL" == "1" ]; then
        echo "安装k8s kube-flannel 网络"
        kubectl apply -f kube-flannel.yml
    else
        echo "calico 需要镜像:"`cat calico.yaml |grep docker.io|awk {'print $2'}`
        echo "手动拉取 calico 镜像"
        for i in `cat calico.yaml |grep docker.io|awk {'print $2'}`;do ctr images pull $i;done
        echo "镜像列表:"`ctr images ls`
        echo "安装 k8s calico 网络"
        kubectl apply -f calico.yaml
    fi

    echo "cp kubectl_aliases"
    `cp .kubectl_aliases ~/.kubectl_aliases`
    sed -i "/kubectl_aliases/d" ~/.bashrc
    echo "[ -f ~/.kubectl_aliases ] && source ~/.kubectl_aliases" >> ~/.bashrc
fi

# 查看 kubelet 情况
# systemctl status kubelet
# journalctl -xeu kubelet
