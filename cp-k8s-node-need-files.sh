if [ ! -f "cri-containerd-cni-1.6.16-linux-amd64.tar.gz" ]; then
  echo "start download cri-containerd-cni-1.6.16-linux-amd64.tar.gz from github"
  wget -t 0 -T 180 https://github.com/containerd/containerd/releases/download/v1.6.16/cri-containerd-cni-1.6.16-linux-amd64.tar.gz -O cri-containerd-cni-1.6.16-linux-amd64.tar.gz
  if [ `ls -l | grep "cri-containerd-cni-1.6.16-linux-amd64.tar.gz" | grep -v grep | awk -F " " '{print $5}'` -gt 120847122 ]; then
    echo 'download finsh from github'
  else
    echo "download failure from github, need wget https://www.qiushaocloud.top/common-static/k8s-files/cri-containerd-cni-1.6.16-linux-amd64.tar.gz"
    wget -t 3 -T 180 https://www.qiushaocloud.top/common-static/k8s-files/cri-containerd-cni-1.6.16-linux-amd64.tar.gz -O cri-containerd-cni-1.6.16-linux-amd64.tar.gz

    if [ `ls -l | grep "cri-containerd-cni-1.6.16-linux-amd64.tar.gz" | grep -v grep | awk -F " " '{print $5}'` -gt 120847122 ]; then
      echo "download cri-containerd-cni-1.6.16-linux-amd64.tar.gz file success"
    else
      echo "download cri-containerd-cni-1.6.16-linux-amd64.tar.gz file failure, need remove file, ls -l:"`ls -l`
      rm -rf cri-containerd-cni-1.6.16-linux-amd64.tar.gz
    fi
  fi

  echo "file download finsh, ls -l:"`ls -l`
else
  echo "exit cri-containerd-cni-1.6.16-linux-amd64.tar.gz file"
fi

if [ -f "cri-containerd-cni-1.6.16-linux-amd64.tar.gz" ]; then
    echo "tar -zcvf k8s-node-need-files.tgz cni-plugins-linux-amd64-v1.2.0.tgz libseccomp-2.5.1-1.el8.x86_64.rpm cri-containerd-cni-1.6.16-linux-amd64.tar.gz install-k8s.sh reset-k8s.sh"
    tar -zcvf k8s-node-need-files.tgz cni-plugins-linux-amd64-v1.2.0.tgz libseccomp-2.5.1-1.el8.x86_64.rpm cri-containerd-cni-1.6.16-linux-amd64.tar.gz install-k8s.sh reset-k8s.sh
else
    echo "tar -zcvf k8s-node-need-files.tgz cni-plugins-linux-amd64-v1.2.0.tgz libseccomp-2.5.1-1.el8.x86_64.rpm install-k8s.sh reset-k8s.sh"
    tar -zcvf k8s-node-need-files.tgz cni-plugins-linux-amd64-v1.2.0.tgz libseccomp-2.5.1-1.el8.x86_64.rpm install-k8s.sh reset-k8s.sh
fi