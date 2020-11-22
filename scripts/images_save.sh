#!/bin/bash

# 保存镜像
# https://kube-images.oss-cn-beijing.aliyuncs.com/v1.16.15/k8s%E9%95%9C%E5%83%8F.zip
docker images | grep -v REPOSITORY | awk -F" " '{print $1":"$2}' > /tmp/images_list

for line in $(cat  /tmp/images_list)
do
 #echo $line
 #echo `basename $line`
 #echo `basename $line`.tar.gz
 docker save -o `basename $line`.tar.gz  $line
done
