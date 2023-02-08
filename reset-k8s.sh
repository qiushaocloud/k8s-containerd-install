if [ -f "kubeadm-config.yml" ]; then
    echo "kubeadm reset -f --kubeconfig $PWD/kubeadm-config.yml --cri-socket unix:///run/containerd/containerd.sock"
    kubeadm reset -f --kubeconfig $PWD/kubeadm-config.yml --cri-socket unix:///run/containerd/containerd.sock
else
    echo "kubeadm reset -f --cri-socket unix:///run/containerd/containerd.sock"
    kubeadm reset -f --cri-socket unix:///run/containerd/containerd.sock 
fi

