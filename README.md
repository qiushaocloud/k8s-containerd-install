# k8s-containerd-install
ubuntu/centos 安装 k8s 集群所需环境，k8s 使用 1.26.0, 容器使用 containerd(不使用docker)，使用 ipvs。 
支持 init/join k8s 集群，安装网络组件 calico/flannel，安装配置 ingress-nginx，安装配置 metallb

### 配置 /etc/hosts, 需要根据您的实际情况配置, k8s-master、k8s-node01、k8s-node02、k8s-nodexx 您自行修改成您机器的 hostname 以及 ip 地址【k8s 所有节点(即: master 和 node)都需要配置】
``` shell
sed -i "/k8s-master/d" /etc/hosts
sed -i "/k8s-node01/d" /etc/hosts
sed -i "/k8s-node02/d" /etc/hosts
cat >> /etc/hosts << EOF
192.168.1.xx k8s-master
192.168.1.x1 k8s-node01
192.168.1.x2 k8s-node02
EOF
```

###  k8s 所有节点(即: master 和 node) 安装 k8s 所需环境
1. 执行命令安装 k8s 环境: `bash install-k8s.sh`
2. 执行命令: `source ~/.bashrc`
3. 因为重新设置 kube-apiserver 端口范围，服务会重启，需要等待一段时间，等服务重启完，把网络组件安装完就行了
4. 等待一段时间后，执行命令查看 pod 是否都已经 Ready 了, 命令: `kubectl get pod -A`
5. 如果长时间不好，可以尝试将机器重新启动下

### k8s master 节点 init 集群
1. 拷贝 env.tpl 为 .env, 并且根据自己情况修改里面的配置，拷贝命令: `cp env.tpl .env`
2. 执行命令 init 集群: `bash init-k8s.sh` 
3. 保存好 init 完后 join k8s 命令(即: kubeadm join 部分)，node 节点需要用该命令加入 k8s【注意：kubeadm join 需要加上 --cri-socket unix:///run/containerd/containerd.sock】, 例如: 
``` shell
kubeadm join 192.168.1.xx:6443 --token abcded.1234567890abcdef \
    --discovery-token-ca-cert-hash sha256:36kiuydcf921ff6dhg6y5471857bfe9b529f6datrey0825ae1add79e7aefd1c2 \
    --cri-socket unix:///run/containerd/containerd.sock
```

### k8s master 安装 helm
1. 运行 `bash install-helm.sh`

### k8s node 节点加入集群
1. 使用 k8s master 节点 init 完后的 kubeadm join 命令加入集群 【注意：join 需要加上 --cri-socket unix://var/run/cri-dockerd.sock】, 例如:
``` shell
kubeadm join 192.168.1.xx:6443 --token abcded.1234567890abcdef \
    --discovery-token-ca-cert-hash sha256:36kiuydcf921ff6dhg6y5471857bfe9b529f6datrey0825ae1add79e7aefd1c2 \
    --cri-socket unix:///run/containerd/containerd.sock
```

### 安装配置 ingress-nginx 【根据自己需求看是否安装】
1. 进入 ingress-nginx
2. 设置 label: `bash set-master-label-ingress.sh`
3. 安装: `kubectl apply -f deploy.yaml`

### 安装配置 metallb【根据自己需求看是否安装，另外需要看你的网络是否支持 metallb 所需要求】
1. 进入 metallb-system
2. 拷贝文件：`cp metallb-configMap.yaml.tpl metallb-configMap.yaml`
3. 根据你自己的情况配置 metallb-configMap.yaml, 主要修改 addresses 部分
4. 执行命令：`bash apply.sh`



#### 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request



#### 分享者信息

1. 分享者邮箱: qiushaocloud@126.com
2. [分享者网站](https://www.qiushaocloud.top)
3. [分享者自己搭建的 gitlab](https://gitlab.qiushaocloud.top/qiushaocloud) 
3. [分享者 gitee](https://gitee.com/qiushaocloud/dashboard/projects) 
3. [分享者 github](https://github.com/qiushaocloud?tab=repositories) 

