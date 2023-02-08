wget https://get.helm.sh/helm-v3.10.3-linux-amd64.tar.gz -O helm-v3.10.3-linux-amd64.tar.gz
tar -zxvf helm-v3.10.3-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
helm version
rm -rf helm-v3.10.3-linux-amd64.tar.gz
rm -rf linux-amd64
