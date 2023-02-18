if [ -f "cri-containerd-cni-1.6.16-linux-amd64.tar.gz" ]; then
    echo "tar -zcvf k8s-node-need-files.tgz cni-plugins-linux-amd64-v1.2.0.tgz libseccomp-2.5.1-1.el8.x86_64.rpm cri-containerd-cni-1.6.16-linux-amd64.tar.gz install-k8s.sh reset-k8s.sh"
    tar -zcvf k8s-node-need-files.tgz cni-plugins-linux-amd64-v1.2.0.tgz libseccomp-2.5.1-1.el8.x86_64.rpm cri-containerd-cni-1.6.16-linux-amd64.tar.gz install-k8s.sh reset-k8s.sh
else
    echo "tar -zcvf k8s-node-need-files.tgz cni-plugins-linux-amd64-v1.2.0.tgz libseccomp-2.5.1-1.el8.x86_64.rpm install-k8s.sh reset-k8s.sh"
    tar -zcvf k8s-node-need-files.tgz cni-plugins-linux-amd64-v1.2.0.tgz libseccomp-2.5.1-1.el8.x86_64.rpm install-k8s.sh reset-k8s.sh
fi