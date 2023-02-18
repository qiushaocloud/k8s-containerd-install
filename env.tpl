# K8S port
APISERVER_BIND_PORT=6443

# 指定 control-plane-endpoint 的域名，例如: k8s-control-plane-endpoint-intranet.qiushaocloud.local
CONTROL_PLANE_ENDPOINT=""

# 指定 k8s token，例如: abcded.1234567890abcdef
K8S_TOKEN=""

# calico IP_AUTODETECTION_METHOD 的值，用于指定网卡, 例如: interface=ens32 或者 can-reach=www.baidu.com
IP_AUTODETECTION_METHOD_VALUE=""

# 是否使用 flannel 网络, 1/0, 1 表示使用 flannel，0 表示使用 calico，默认使用 calico
IS_USE_FLANNEL=0