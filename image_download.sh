# cat image_download.sh
#!/bin/bash

kubeadm config images pull --config kubeadm-config.yml

# images_list='
# registry.aliyuncs.com/google_containers/kube-apiserver:v1.26.0
# registry.aliyuncs.com/google_containers/kube-controller-manager:v1.26.0
# registry.aliyuncs.com/google_containers/kube-scheduler:v1.26.0
# registry.aliyuncs.com/google_containers/kube-proxy:v1.26.0
# registry.aliyuncs.com/google_containers/pause:3.9
# registry.aliyuncs.com/google_containers/etcd:3.5.6-0
# registry.aliyuncs.com/google_containers/coredns:v1.9.3
# '

# for i in $images_list
# do
#     crictl pull $i
# done