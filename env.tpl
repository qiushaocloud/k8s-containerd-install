# K8S port
APISERVER_BIND_PORT=6443

# 指定 control-plane-endpoint 的域名，例如: k8s-control-plane-endpoint-intranet.qiushaocloud.local
CONTROL_PLANE_ENDPOINT=""

# 指定 k8s token，例如: abcded.1234567890abcdef
K8S_TOKEN=""

# calico IP_AUTODETECTION_METHOD 的值，用于指定网卡, 例如: interface=ens* 或 interface=ens32 或 can-reach=www.baidu.com 【注：使用 interface=ens32 需要所有机器上的网卡都是ens32，否则请使用 interface=ens*】
IP_AUTODETECTION_METHOD_VALUE="interface=ens*"

# 是否使用 flannel 网络, 1/0, 1 表示使用 flannel，0 表示使用 calico，默认使用 calico
IS_USE_FLANNEL=0