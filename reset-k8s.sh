crictl ps -a|grep Exited|awk '{print $1}'|(xargs crictl rm -f || true)
rm -rf /etc/cni/net.d
ipvsadm --clear

if [ -f "kubeadm-config.yml" ]; then
    echo "kubeadm reset -f --kubeconfig $PWD/kubeadm-config.yml --cri-socket unix:///run/containerd/containerd.sock"
    kubeadm reset -f --kubeconfig $PWD/kubeadm-config.yml --cri-socket unix:///run/containerd/containerd.sock
else
    echo "kubeadm reset -f --cri-socket unix:///run/containerd/containerd.sock"
    kubeadm reset -f --cri-socket unix:///run/containerd/containerd.sock 
fi

