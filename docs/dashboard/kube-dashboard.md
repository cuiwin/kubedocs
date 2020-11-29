## 安装Dashboard 

官方源码链接：

```
https://github.com/kubernetes/dashboard
```

安装 Dashboard 

```
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.4/aio/deploy/recommended.yaml
```

下载 yaml

```
mkdir kube-dashboard && cd kube-dashboard
wget
https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.4/aio/deploy/recommended.yaml
```

安装 Dashboard 

```
$ kubectl apply -f recommended.yaml
```

查看recommended.yaml 的配置，目前dashboard的service设置的是Cluster IP 方式。如果在集群外访问，可以修改成NodePort 方式。

```
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  type: NodePort
  ports:
    - nodePort: 32576
      port: 443
      protocol: TCP
      targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard
```

修改后生效：

```
$ kubectl apply -f recommended.yaml
```

查看

```
root@k8s-dev-master-60:~/kube-dashboard# kubectl get  svc -n kubernetes-dashboard
NAME                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)         AGE
dashboard-metrics-scraper   ClusterIP   10.20.122.95    <none>        8000/TCP        17m
kubernetes-dashboard        NodePort    10.20.186.202   <none>        443:32576/TCP   17m

```

浏览器打开网址访问：

```
https://192.168.37.60:32576/
```

打开登陆界面了！

##  登陆方式

### Token认证方式登录

编辑 ServiceAcount  service_account_dashboard.yaml

```
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: admin-dashboard
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: admin-dashboard
  namespace: kubernetes-dashboard
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-dashboard
  namespace: kubernetes-dashboard
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
```

创建Service Account

```
kubectl apply -f service_account_dashboard.yaml
```

获取token

```
kubectl -n kubernetes-dashboard  get secret | grep admin-dashboard

kubectl describe secrets admin-dashboard-token-9r6cw -n kubernetes-dashboard
```

