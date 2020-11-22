## Kubeadm方式安装k8s

使用k8s官方提供的部署工具kubeadm自动安装k8s，需要再master和node节点上安装docker等组件，然后初始化，把管理端的控制服务和node上的服务都以pod的方式运行。

## 安装步骤

### 安装docker环境

安装18.09.9版本，在三台服务器上都安装

```
root@node-40:~# cat docker-install.sh 

#!/bin/bash
# step 1: 安装必要的一些系统工具
sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
# step 2: 安装GPG证书
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
# Step 3: 写入软件源信息
sudo add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
# Step 4: 更新并安装 Docker-CE
sudo apt-get -y update

apt-cache madison docker-ce docker-ce-cli

sudo apt-get -y install docker-ce=5:18.09.9~3-0~ubuntu-bionic  docker-ce-cli=5:18.09.9~3-0~ubuntu-bionic

docker version 

sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://44l7zra5.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker

```

### 安装kubelet\kubeadm\kubectl

配置阿里云镜像的kubernetes源

**kubectl**

```
kubectl和docker-cli相同的功能
https://kubernetes.io/zh/docs/reference/kubectl/docker-cli-to-kubectl/
```

**kubelet**

```
kubelet 是在每个节点上运行的主要 “节点代理”。kubelet 以 PodSpec 为单位来运行任务，PodSpec 是一个描述 pod 的 YAML 或 JSON 对象。 kubelet 运行多种机制（主要通过 apiserver）提供的一组 PodSpec，并确保这些 PodSpecs 中描述的容器健康运行。 不是 Kubernetes 创建的容器将不在 kubelet 的管理范围。

除了来自 apiserver 的 PodSpec 之外，还有三种方法可以将容器清单提供给 Kubelet。

文件：通过命令行传入的文件路径。kubelet 将定期监听该路径下的文件以获得更新。监视周期默认为 20 秒，可通过参数进行配置。

HTTP 端点：HTTP 端点以命令行参数传入。每 20 秒检查一次该端点（该时间间隔也是可以通过命令行配置的）。

HTTP 服务：kubelet 还可以监听 HTTP 并响应简单的 API（当前未指定）以提交新的清单。
```

安装**kubeadm**脚本

```
root@node-40:~# cat kubeadm-install.sh 

#!/bin/bash
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

apt-get install kubeadm=1.15.3-00  kubelet=1.15.3-00  kubectl=1.15.3-00

```

查看kubeadm版本和需要的镜像

```
$  kubeadm version

#在没有互联网或者无法连接不到国外网站下载镜像的时候，需要手动下载镜像。
$  kubeadm config images list --kubernetes-version v1.15.3
k8s.gcr.io/kube-apiserver:v1.15.3
k8s.gcr.io/kube-controller-manager:v1.15.3
k8s.gcr.io/kube-scheduler:v1.15.3
k8s.gcr.io/kube-proxy:v1.15.3
k8s.gcr.io/pause:3.1
k8s.gcr.io/etcd:3.3.10
k8s.gcr.io/coredns:1.3.1

#替换k8s.gcr.io为国内阿里源，提前下载下来
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.15.3
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-controller-manager:v1.15.3
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-scheduler:v1.15.3
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-proxy:v1.15.3
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.1
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:3.3.10
docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:1.3.1

```

初始化master

```
kubeadm  init \
--apiserver-advertise-address=192.168.37.50 \
--apiserver-bind-port=6443 \
--kubernetes-version=v1.15.3 \
--pod-network-cidr=10.10.0.0/16 \
--service-cidr=10.20.0.0/16 \
--service-dns-domain=linux37.local \
--image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers \
--ignore-preflight-errors=swap

#--apiserver-advertise-address  API Server 将要监听的监听地址，为本机 IP
```

安装成功后，提醒我们需要再进行进一步的配置

**1）master 配置 kube 证书**

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
  
#具备了这个证书，就可以调用命令了
root@node-40:~# kubectl get nodes
```

**2)  部署网络插件**

```
#查看所有支持的网络插件
https://kubernetes.io/docs/concepts/cluster-administration/addons/

选择flannel
https://github.com/coreos/flannel

#添加网络插件
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

#注意，在公司使用harbor的时候，会把flannel的镜像下载后，上传到harbor上。然后修改kube-flannel.yml
中的images仓库地址。
```

检查状态

```
kubectl get cs

kubectl get nodes

kubectl get pods --all-namespaces
```

**3）添加节点**

两个node节点，分别执行join命令，加入所需集群的token默认是24小时过期。

```
#列出token信息
kubeadm token list

#如果失效创建一个新的,同时可以打印加入的语句。
kubeadm token create --print-join-command

#获取ca证书sha256编码hash值
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
```

```
kubeadm join 192.168.37.40:6443 --token hx4sqn.1szaikw9xz448u5f \
    --discovery-token-ca-cert-hash sha256:4bda57d2f32d4b7255a641937151e16fef0f5ee53601344d730cb9a832e07cd6
```

```
各 node 节点都要安装 docker kubeadm kubelet ，因此都要执行安装**kubeadm**脚本步骤，即配置 apt 仓库、配置 docker 加速器、安装命令、启动 kubelet 服务。
```

检查node节点状态

```
root@node-40:~# kubectl get nodes
NAME      STATUS   ROLES    AGE     VERSION
node-40   Ready    master   55m     v1.15.3
node-41   Ready    <none>   5m52s   v1.15.3
node-42   Ready    <none>   3m9s    v1.15.3

```

### k8s创建容器并测试

```
kubectl run net-test1 --image=alpine --replicas=2 sleep 360000

root@node-40:~# kubectl get pods -o wide
NAME                         READY   STATUS    RESTARTS   AGE   IP          NODE      NOMINATED NODE   READINESS GATES
net-test1-8596df4559-25kvm   1/1     Running   0          58s   10.10.1.2   node-41   <none>           <none>
net-test1-8596df4559-xzbb8   1/1     Running   0          58s   10.10.2.2   node-42   <none>           <none>

root@node-40:~# kubectl exec -it net-test1-8596df4559-25kvm sh

```

遇到的一个问题，flannel，yaml文件中的ip地址段和kubeadm init命令指定的地址段不一致。在各node节点上，可以查看，

```
root@node-41:~# cat /run/flannel/subnet.env 
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.10.1.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true
```

修改了flannel的yaml文件，第二天重启电脑网络正常了

## 维护集群

### 删除node节点

### 添加node节点

### CoreDNS相关

获取kube-system命名空间内的deployment。

```
root@node-40:~# kubectl get deployment -n kube-system
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
coredns  2/2     2           2           10d

```

扩展副本数量，到3个。

```
kubectl scale --replicas=3 deployment/coredns -n kube-system
```

## kubeadm升级k8s集群

升级k8s集群必须先升级kubeadm版本到目的k8s版本，也就是说kubeadm是k8s升级的“准生证”,本次计划升级

v1.15.3升级到v1.15.4

**注意：升级可能会对业务影响，尽量在晚上进行**

### 升级kubeadm

验证当前k8s的版本

```
kubeadm version
```

查看所有版本

```
 #查看 k8s 版本列表
apt-cache madison kubeadm 

#升级命令
apt-get install kubeadm=1.15.4-00

#需要再master控制端和各个node节点上都执行升级kubeadm工具。

```

### 升级k8s

master上查看kubeadm升级命令

```
kubeadm  upgrade  --help
kubeadm  upgrade  plan  #查看升级计划
当kubeadm升级一个版本之后，就可以查看k8s的升级计划
```

```
Upgrade to the latest version in the v1.15 series:

COMPONENT            CURRENT   AVAILABLE
API Server           v1.15.3   v1.15.4
Controller Manager   v1.15.3   v1.15.4
Scheduler            v1.15.3   v1.15.4
Kube Proxy           v1.15.3   v1.15.4
CoreDNS              1.3.1     1.3.1
Etcd                 3.3.10    3.3.10

You can now apply the upgrade by executing the following command:

	kubeadm upgrade apply v1.15.4

_____________________________________________________________________

```

master上执行升级

```
kubeadm upgrade apply v1.15.4
```

master升级node节点的配置文件

```
kubeadm upgrade node config --kubelet-version 1.15.4
```

各node节点，安装新版本的kubelet\kubeadm\kubectl

```
apt-get install kubelet=1.15.4-00  kubectl=1.15.4-00
```

### 使用技巧

有时候，关机，再开机，运行kubectl get pod -A，发现kubeadm的一些pod状态不正常，这时候，可以使用命令删除pod，这样kubectladm会自动启动新的pod。

```
kubectl delete pod  coredns-6967fb4995-snx85 -n kube-system   #注意增加namespace
```

续集：删了好像没有自动重建，一直没有找到可以让node节点再次创建pod的方法（coredns），开始考虑是否先把该node节点从集群中删除。
