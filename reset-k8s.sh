if [ -f "kubeadm-config.yml" ]; then
    echo "kubeadm reset -f --kubeconfig $PWD/kubeadm-config.yml"
    kubeadm reset -f --kubeconfig $PWD/kubeadm-config.yml
else
    echo "kubeadm reset -f --cri-socket unix:///run/containerd/containerd.sock"
    kubeadm reset -f --cri-socket unix:///run/containerd/containerd.sock 
fi

