#!/bin/bash

fun_diyecho(){
	echo -e "\033[1;$2m $1 \033[0m"
}

case $1 in
init)
	ansible-playbook -i hosts task-cluster-init.yaml
	;;
reset)
	ansible-playbook -i hosts task-cluster-reset.yaml
	;;
*)  
	fun_diyecho "Usage:`basename $0` init | reset " 35
esac