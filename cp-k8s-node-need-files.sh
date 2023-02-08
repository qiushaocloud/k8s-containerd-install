if [ -f "cri-containerd-cni-1.6.16-linux-amd64.tar.gz" ]; then
    echo "tar -zcvf k8s-node-need-files.tgz cni-plugins-linux-amd64-v1.2.0.tgz libseccomp-2.5.1-1.el8.x86_64.rpm cri-containerd-cni-1.6.16-linux-amd64.tar.gz"
    tar -zcvf k8s-node-need-files.tgz cni-plugins-linux-amd64-v1.2.0.tgz libseccomp-2.5.1-1.el8.x86_64.rpm cri-containerd-cni-1.6.16-linux-amd64.tar.gz
else
    echo "tar -zcvf k8s-node-need-files.tgz cni-plugins-linux-amd64-v1.2.0.tgz libseccomp-2.5.1-1.el8.x86_64.rpm"
    tar -zcvf k8s-node-need-files.tgz cni-plugins-linux-amd64-v1.2.0.tgz libseccomp-2.5.1-1.el8.x86_64.rpm
fi