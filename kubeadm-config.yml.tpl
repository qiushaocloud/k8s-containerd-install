apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  # 指定token
  token: <K8S_TOKEN>
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  # 修改为主节点IP地址
  advertiseAddress: <ADVERTISE_ADDRESS>
  bindPort: <BIND_PORT>
nodeRegistration:
  # 修改为 containerd
  criSocket: unix:///run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  # 节点名改成主节点的主机名
  name: <MY_HOSTNAME>
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/control-plane
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
# 虚拟IP和haproxy端口
controlPlaneEndpoint: "<CONTROL_PLANE_ENDPOINT>"
controllerManager: {}
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
# 换成国内的源
imageRepository: registry.aliyuncs.com/google_containers
kind: ClusterConfiguration
# 修改版本号 必须对应
kubernetesVersion: 1.26.0
networking:
  # 新增该配置 固定为 10.244.0.0/16，用于后续 Calico网络插件
  podSubnet: 10.244.0.0/16
  dnsDomain: cluster.local
  # 固定svc 网段
  serviceSubnet: 10.1.0.0/16
scheduler: {}

---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
featureGates:
  SupportIPVSProxyMode: true
mode: ipvs