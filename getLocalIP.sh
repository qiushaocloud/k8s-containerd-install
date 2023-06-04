#!/bin/sh

local_ip=''

function getIpAddr(){
	# 获取IP命令
	if [[ "$(uname)" == "Linux" ]]; then
		if [[ -f "/etc/lsb-release" ]]; then
			echo "Ubuntu"
			ipaddr=$(ifconfig -a | grep 'inet ' | awk '{print $2}' | cut -d ':' -f2 | grep -vE "127.0.0.1")
		elif [[ -f "/etc/redhat-release" ]]; then
			echo "CentOS"
			ipaddr=$(ip addr show | grep 'inet ' | awk '{print $2}' | cut -d '/' -f1 | grep -vE "127.0.0.1")
		else
			echo "Unknown Linux distribution"
			exit 1
		fi
	else
		echo "Unsupported operating system"
		exit 1
	fi
	array=(`echo $ipaddr | tr '\n' ' '` ) 	# IP地址分割，区分是否多网卡
	#array=(172.20.32.214 192.168.1.10);
	num=${#array[@]}  						#获取数组元素的个数
 
	# 选择安装的IP地址
	if [ $num -eq 1 ]; then
		#echo "*单网卡"
		local_ip=${array[*]}
	elif [ $num -gt 1 ];then
		echo -e "\033[035m******************************\033[0m"
		echo -e "\033[036m*    请选择IP地址		\033[0m"
		for ((i=0; i<num; i ++))
		do
			echo -e "\033[032m*      $i : ${array[$i]}                \033[0m"
		done
		echo -e "\033[035m******************************\033[0m"
		#选择需要安装的服务类型
		input=""
		while :
		do
			read -r -p "*请选择IP地址(序号): " input
			echo "current input item: ${array[$input]}"
			if [ -z "${array[$input]}" ]; then
			  	echo *请输入有效的数字:
			else
				local_ip=${array[$input]}
				echo "local_ip: $local_ip"
				break
			fi
		done
	else
		echo -e "\033[31m*未设置网卡IP，请检查服务器环境！ \033[0m"
		exit 1
	fi
} 
 
# 校验IP地址合法性
function isValidIp() {
	local ip=$1
	local ret=1
 
	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		ip=(${ip//\./ }) # 按.分割，转成数组，方便下面的判断
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		ret=$?
	fi
	return $ret
}
 
getIpAddr	#自动获取IP
isValidIp ${local_ip}	# IP校验
if [ $? -ne 0 ]; then
	echo -e "\033[31m*自动获取的IP地址无效，请重试！ \033[0m"
	exit 1
fi
echo "*选择IP地址为：${local_ip}"
echo ${local_ip} > /tmp/getLocalIpResult
echo 'cat /tmp/getLocalIpResult:'`cat /tmp/getLocalIpResult`
