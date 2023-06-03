# k8s-containerd-install
ubuntu/centos 安装 k8s 集群所需环境，k8s 使用 1.26.5, 容器使用 containerd(不使用docker)，使用 ipvs。 
支持 init/join k8s 集群，安装网络组件 calico/flannel，安装配置 ingress-nginx，安装配置 metallb



### 实验机器配置
* ubuntu 实验机器
  > 3台 ubuntu server 22.04
* centos 实验机器
  > 3台 centos7 server



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

### k8s node 节点所需要的文件可以单独拷贝过去
1. 执行拷贝命令: `bash cp-k8s-node-need-files.sh`
2. 将文件 k8s-node-need-files.tgz 拷贝 k8s node 节点上，比如拷贝到 /root/k8s-node-install-files 上
3. 在 k8s node 节点 /root/k8s-node-install-files 下解压: tar -zxvf k8s-node-need-files.tgz

###  k8s 所有节点(即: master 和 node) 安装 k8s 所需环境
1. 执行命令安装 k8s 环境: `bash install-k8s.sh`
2. 执行命令: `source ~/.bashrc`

### k8s master 节点 init 集群
1. 拷贝 env.tpl 为 .env, 并且根据自己情况修改里面的配置，拷贝命令: `cp env.tpl .env`
2. 执行命令 reset 集群: `bash reset-k8s.sh`
3. 执行命令 init 集群: `bash init-k8s.sh`
4. 查看 k8s node 节点加入的命令: `cat k8s-node-join-info`，得到的信息例如: 
``` shell
kubeadm join 192.168.1.xx:6443 --token abcded.1234567890abcdef \
    --discovery-token-ca-cert-hash sha256:36kiuydcf921ff6dhg6y5471857bfe9b529f6datrey0825ae1add79e7aefd1c2 \
    --cri-socket unix:///run/containerd/containerd.sock
```
5. 您也可以从 kubeadm-init.log 中获取 join k8s 命令(即: kubeadm join 部分)，node 节点需要用该命令加入 k8s【注意：kubeadm join 需要加上 --cri-socket unix:///run/containerd/containerd.sock】, 例如: 
``` shell
kubeadm join 192.168.1.xx:6443 --token abcded.1234567890abcdef \
    --discovery-token-ca-cert-hash sha256:36kiuydcf921ff6dhg6y5471857bfe9b529f6datrey0825ae1add79e7aefd1c2 \
    --cri-socket unix:///run/containerd/containerd.sock
```
6. 因为重新设置 kube-apiserver 端口范围，服务会重启，需要等待一段时间，等服务重启完，把网络组件安装完就行了
7. 等待一段时间后，执行命令查看 pod 是否都已经 Ready 了, 命令: `kubectl get pod -A`
8. 如果长时间不好，可以尝试将机器重新启动下
9. 执行命令: `source ~/.bashrc`

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
2. 设置 master 污点 NoSchedule(如果需要部署在master上): `bash set-master-NoSchedule.sh`
3. 设置 label: `bash set-master-label-ingress.sh`
4. 安装: `kubectl apply -f deploy.yaml`

### 安装配置 metallb【根据自己需求看是否安装，另外需要看你的网络是否支持 metallb 所需要求】
1. 进入 metallb-system
2. 拷贝文件：`cp metallb-configMap.yaml.tpl metallb-configMap.yaml`
3. 根据你自己的情况配置 metallb-configMap.yaml, 主要修改 addresses 部分
4. 执行命令：`bash apply.sh`

### 使用 nerdctl 代替 docker 【根据自己需求看是否安装】
1. 解压缩: `tar -xvf nerdctl-1.2.0-linux-amd64.tar -C /usr/local`
2. 设置链接: `ln -s /usr/local/nerdctl /usr/bin/nerdctl`
3. 如果 nerdctl 不习惯, 设置别名为 docker
```
sed -i '/alias docker=/d' $HOME/.bashrc
sed -i '/alias docker-compose=/d' $HOME/.bashrc
echo 'alias docker=nerdctl' >> $HOME/.bashrc
echo 'alias docker-compose="nerdctl compose"' >> $HOME/.bashrc
source $HOME/.bashrc
```

### 安装 kubectl 命令补全工具(bash-completion) 【根据自己需求看是否安装】
* centos 安装 bash-completion
``` shell
yum install bash-completion -y
source /usr/share/bash-completion/bash_completion
sed -i '/source <(kubectl completion bash)/d' ~/.bashrc
echo "source <(kubectl completion bash)" >> ~/.bashrc
```
* ubuntu 安装
``` shell
apt install bash-completion -y
source /usr/share/bash-completion/bash_completion
sed -i '/source <(kubectl completion bash)/d' ~/.bashrc
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc
```

### ctr、crictl、nerdctl 以及 docker 对比
* ctr、crict、docker 命令对比
> ctr是由containerd提供的一个客户端工具。
> crictl是CRI兼容的容器运行时命令接口，和containerd无关，由kubernetes提供，可以使用它来检查和调试k8s节点上的容器运行时和应用程序。

| 命令               | docker         | ctr                            | crictl         |
| ------------------ | -------------- | ------------------------------ | -------------- |
| 查看镜像           | docker images  | ctr image ls                   | crictl images  |
| 拉取镜像           | docker pull    | ctr image pull                 | crictl pull    |
| 推送镜像           | docker push    | ctr image push                 | 无             |
| 删除镜像           | docker rmi     | ctr image rm                   | crictl rmi     |
| 导入镜像           | docker load    | ctr image import               | 无             |
| 导出镜像           | docker save    | ctr image export               | 无             |
| 修改镜像标签       | docker tag     | ctr image tag                  | 无             |
| 创建一个新的容器   | docker create  | ctr container create           | crictl create  |
| 运行一个新的容器   | docker run     | ctr run                        | 无             |
| 删除容器           | docker rm      | ctr container rm               | crictl rm      |
| 查看运行容器       | docker ps      | ctr task ls / ctr container ls | crictl ps      |
| 启动已有容器       | docker start   | ctr task start                 | crictl start   |
| 关闭已有容器       | docker stop    | ctr task kill                  | crictl stop    |
| 在容器内部执行命令 | docker exec    | 无                             | crictl exec    |
| 查看容器内信息     | docker inspect | ctr container info             | crictl inspect |
| 查看容器日志       | docker logs    | 无                             | crictl logs    |
| 查看容器资源       | docker stats   | 无                             | crictl stats   |
* nerdctl 与 docker 对比
> nerdctl 是与 Docker 兼容的 CLI for Containerd，其支持 compose
> nerdctl 和 docker命令行语法类似

``` text
nerdctl 发布包含两安装版本：
- Mininal：仅包含nerdctl二进制文件以及rootless模式下的辅助安装脚本
- Full：包含containerd、CNI、runC、BuildKit等完整组件
```


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

