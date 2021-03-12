##  简介

kubernetes 集群资源监控之前可以通过 heapster 来获取数据，在 1.11 开始开始逐渐废弃 heapster 了，采用 metrics-server 来代替，metrics-server 是集群的核心监控数据的聚合器，它从 kubelet 公开的 Summary API 中采集指标信息，metrics-server 是扩展的 APIServer，依赖于[kube-aggregator](https://links.jianshu.com/go?to=https%3A%2F%2Fgithub.com%2Fkubernetes%2Fkube-aggregator)，因为我们需要在 APIServer 中开启相关参数。

官方链接：https://github.com/kubernetes-sigs/metrics-server

##  安装

```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.4.2/components.yaml
```

后就可以看到 metrics-server 运行起来：

```
kubectl -n kube-system get pods -l k8s-app=metrics-server
```



##  遇到问题

1） 镜像直接拉取失败

```
kubectl -n kube-system  describe pod metrics-server-59d5c795dc-zqjgk

提示：Error: ImagePullBackOff
镜像访问不到：k8s.gcr.io/metrics-server/metrics-server:v0.4.1
k8s.gcr.io/metrics-server/metrics-server:v0.4.1  是谷歌镜像，国内访问不到，可以考虑到阿里云镜像源进行搜索，可以找到其他用户下载上传的镜像，下载下来后，重新打tag即可
```

2） metrics-server pod 启动后经过几十秒后失败

```
kubectl logs -n kube-system  metrics-server-59ff97d56-8k2n6

提示：cannot validate certificate for 192.168.37.62 because it doesn't contain any

官方的github issueshttps://github.com/kubernetes-sigs/metrics-server/issues/637


解决方法：
1）添加一行- --kubelet-insecure-tls
2）kubectl -f  components.yaml

 template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --kubelet-insecure-tls
        image: k8s.gcr.io/metrics-server/metrics-server:v0.4.1

```



##  参考链接

https://blog.csdn.net/shenhonglei1234/article/details/111171525

https://blog.csdn.net/liukuan73/article/details/81352637?utm_medium=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-2.control&dist_request_id=33c43c35-c972-4f25-9a9a-1190ebf72165&depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-2.control

国内同步镜像

https://blog.csdn.net/networken/article/details/84571373?utm_medium=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-4.control&dist_request_id=&depth_1-utm_source=distribute.pc_relevant.none-task-blog-BlogCommendFromMachineLearnPai2-4.control