#!/bin/bash

if [ ! $1 ]; then
  echo "need version to continue"
  exit
else
  version=$1
fi


apt-get update && apt-get install -y apt-transport-https
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
apt-get update
#查看版本信息
apt-cache madison kubeadm kubelet kubectl
#默认安装的是最新版本，应该先查看下版本，再安装
#apt-get install -y kubelet kubeadm kubectl

apt-get install kubeadm=$version  kubelet=$version  kubectl=$version