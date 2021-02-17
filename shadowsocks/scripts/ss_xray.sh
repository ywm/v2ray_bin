#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

eval `dbus export ss`
source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
xray_CONFIG_FILE="/koolshare/ss/v2ray.json"
#url_main="https://raw.githubusercontent.com/hq450/fancyss/master/xray_binary"
url_main="https://raw.githubusercontent.com/cary-sas/v2ray_bin/main/380_armv5/xray"
url_back=""

get_latest_version(){
	rm -rf /tmp/xray_latest_info.txt
	echo_date "检测xray最新版本..."
	curl --connect-timeout 8 -s $url_main/latest.txt > /tmp/xray_latest_info.txt
	if [ "$?" == "0" ];then
		if [ -z "`cat /tmp/xray_latest_info.txt`" ];then
			echo_date "获取xray最新版本信息失败！使用备用服务器检测！"
			get_latest_version_backup
		fi
		if [ -n "`cat /tmp/xray_latest_info.txt|grep "404"`" ];then
			echo_date "获取xray最新版本信息失败！使用备用服务器检测！"
			get_latest_version_backup
		fi
		V2VERSION=`cat /tmp/xray_latest_info.txt | sed 's/v//g'` || 0
		echo_date "检测到xray最新版本：v$V2VERSION"
		if [ ! -f "/koolshare/bin/xray" ];then
			echo_date "xray安装文件丢失！重新下载！"
			CUR_VER="0"
		else
			CUR_VER=`xray -version 2>/dev/null | head -n 1 | cut -d " " -f2 | sed 's/v//g'` || 0
			echo_date "当前已安装xray版本：v$CUR_VER"
		fi
		COMP=`versioncmp $CUR_VER $V2VERSION`
		if [ "$COMP" == "1" ];then
			[ "$CUR_VER" != "0" ] && echo_date "xray已安装版本号低于最新版本，开始更新程序..."
			update_now v$V2VERSION
		else
			xray_LOCAL_VER=`/koolshare/bin/xray -version 2>/dev/null | head -n 1 | cut -d " " -f2`
			xray_LOCAL_DATE=`/koolshare/bin/xray -version 2>/dev/null | head -n 1 | cut -d " " -f6`
			[ -n "$xray_LOCAL_VER" ] && dbus set ss_basic_xray_version="$xray_LOCAL_VER"
			[ -n "$xray_LOCAL_DATE" ] && dbus set ss_basic_xray_date="$xray_LOCAL_DATE"
			echo_date "xray已安装版本已经是最新，退出更新程序!"
		fi
		rm -rf /tmp/xray
	else
		echo_date "获取xray最新版本信息失败！使用备用服务器检测！"
		get_latest_version_backup
	fi
	rm -rf /tmp/xray_latest_info.txt
}

get_latest_version_backup(){
	echo_date "目前还没有任何备用服务器！"
	echo_date "获取xray最新版本信息失败！请检查到你的网络！"
	echo_date "==================================================================="
	echo XU6J03M6
	exit 1
}

# get_latest_version_backup(){
# 	rm -rf /tmp/xray_latest_info.txt
# 	echo_date "检测xray最新版本..."
# 	curl --connect-timeout 8 -s $url_back/latest.txt > /tmp/xray_latest_info.txt
# 	if [ "$?" == "0" ];then
# 		if [ -z "`cat /tmp/xray_latest_info.txt`" ];then
# 			echo_date "获取xray最新版本信息失败！退出！"
# 			echo_date "==================================================================="
# 			echo XU6J03M6
# 			exit 1
# 		fi
# 		if [ -n "`cat /tmp/xray_latest_info.txt|grep "404"`" ];then
# 			echo_date "获取xray最新版本信息失败！退出！"
# 			echo_date "==================================================================="
# 			echo XU6J03M6
# 			exit 1
# 		fi
# 		V2VERSION=`cat /tmp/xray_latest_info.txt | sed 's/v//g'`
# 		echo_date "检测到xray最新版本：v$V2VERSION"
# 		if [ ! -f "/koolshare/bin/xray" -o ! -f "/koolshare/bin/v2ctl" ];then
# 			echo_date "xray安装文件丢失！重新下载！"
# 			CUR_VER="0"
# 		else
# 			CUR_VER=`xray -version 2>/dev/null | head -n 1 | cut -d " " -f2 | sed 's/v//g'` || 0
# 			echo_date "当前已安装xray版本：v$CUR_VER"
# 		fi
# 		COMP=`versioncmp $V2VERSION $CUR_VER`
# 		if [ "$COMP" == "1" ];then
# 			[ "$CUR_VER" != "0" ] && echo_date "xray已安装版本号低于最新版本，开始更新程序..."
# 			update_now_backup v$V2VERSION
# 		else
# 			xray_LOCAL_VER=`/koolshare/bin/xray -version 2>/dev/null | head -n 1 | cut -d " " -f2`
# 			xray_LOCAL_DATE=`/koolshare/bin/xray -version 2>/dev/null | head -n 1 | cut -d " " -f5`
# 			[ -n "$xray_LOCAL_VER" ] && dbus set ss_basic_xray_version="$xray_LOCAL_VER"
# 			[ -n "$xray_LOCAL_DATE" ] && dbus set ss_basic_xray_date="$xray_LOCAL_DATE"
# 			echo_date "xray已安装版本已经是最新，退出更新程序!"
# 		fi
# 	else
# 		echo_date "获取xray最新版本信息失败！请检查到你的网络！"
# 		echo_date "==================================================================="
# 		echo XU6J03M6
# 		exit 1
# 	fi
# }

update_now(){
	rm -rf /tmp/xray
	mkdir -p /tmp/xray && cd /tmp/xray

	echo_date "开始下载校验文件：md5sum.txt"
	#wget --no-check-certificate --timeout=20 -qO - $url_main/$1/md5sum.txt > /tmp/xray/md5sum.txt
	curl -L -H "Cache-Control: no-cache" -o /tmp/xray/md5sum.txt $url_main/$1/md5sum.txt
	if [ "$?" != "0" ];then
		echo_date "md5sum.txt下载失败！"
		md5sum_ok=0
	else
		md5sum_ok=1
		echo_date "md5sum.txt下载成功..."
	fi
	
	echo_date "开始下载xray程序"
	#wget --no-check-certificate --timeout=20 --tries=1 $url_main/$1/xray
	curl -L -H "Cache-Control: no-cache" -o /tmp/xray/xray $url_main/$1/xray
	if [ "$?" != "0" ];then
		echo_date "xray下载失败！"
		xray_ok=0
	else
		xray_ok=1
		echo_date "xray程序下载成功..."
	fi

	if [ "$md5sum_ok=1" ] && [ "$xray_ok=1" ] ;then
		check_md5sum
	else
		echo_date "使用备用服务器下载..."
		update_now_backup $1
	fi
}

update_now_backup(){
	echo_date "下载失败，请检查你的网络！"
	echo_date "==================================================================="
	echo XU6J03M6
	exit 1
}

# update_now_backup(){
# 	rm -rf /tmp/xray
# 	mkdir -p /tmp/xray && cd /tmp/xray
# 
# 	echo_date "开始下载校验文件：md5sum.txt"
# 	wget --no-check-certificate --timeout=20 -qO - $url_back/$1/md5sum.txt > /tmp/xray/md5sum.txt
# 	if [ "$?" != "0" ];then
# 		echo_date "md5sum.txt下载失败！"
# 		md5sum_ok=0
# 	else
# 		md5sum_ok=1
# 		echo_date "md5sum.txt下载成功..."
# 	fi
# 	
# 	echo_date "开始下载xray程序"
# 	wget --no-check-certificate --timeout=20 --tries=1 $url_back/$1/xray
# 	if [ "$?" != "0" ];then
# 		echo_date "xray下载失败！"
# 		xray_ok=0
# 	else
# 		xray_ok=1
# 		echo_date "xray程序下载成功..."
# 	fi
# 
# 	echo_date "开始下载v2ctl程序"
# 	wget --no-check-certificate --timeout=20 --tries=1 $url_back/$1/v2ctl
# 	if [ "$?" != "0" ];then
# 		echo_date "v2ctl下载失败！"
# 		v2ctl_ok=0
# 	else
# 		v2ctl_ok=1
# 		echo_date "v2ctl程序下载成功..."
# 	fi
# 
# 	if [ "$md5sum_ok=1" ] && [ "$xray_ok=1" ] && [ "$v2ctl_ok=1" ];then
# 		check_md5sum
# 	else
# 		echo_date "下载失败，请检查你的网络！"
# 		echo_date "==================================================================="
# 		echo XU6J03M6
# 		exit 1
# 	fi
# }

check_md5sum(){
	cd /tmp/xray
	echo_date "校验下载的文件!"
	xray_LOCAL_MD5=`md5sum xray|awk '{print $1}'`
	xray_ONLINE_MD5=`cat md5sum.txt|grep -w xray|awk '{print $1}'`
	if [ "$xray_LOCAL_MD5"x = "$xray_ONLINE_MD5"x ] ;then
		echo_date "文件校验通过!"
		install_binary
	else
		echo_date "校验未通过，可能是下载过程出现了什么问题，请检查你的网络！"
		echo_date "==================================================================="
		echo XU6J03M6
		exit 1
	fi
}

install_binary(){
	echo_date "开始覆盖最新二进制!"
	if [ "`pidof xray`" ];then
		echo_date "为了保证更新正确，先关闭xray主进程... "
		killall xray >/dev/null 2>&1
		move_binary
		sleep 1
		start_xray
	else
		move_binary
	fi
}

move_binary(){
	echo_date "开始替换xray二进制文件... "
	mv /tmp/xray/xray /koolshare/bin/xray
	chmod +x /koolshare/bin/xray
	xray_LOCAL_VER=`/koolshare/bin/xray -version 2>/dev/null | head -n 1 | cut -d " " -f2`
	xray_LOCAL_DATE=`/koolshare/bin/xray -version 2>/dev/null | head -n 1 | cut -d " " -f5`
	[ -n "$xray_LOCAL_VER" ] && dbus set ss_basic_xray_version="$xray_LOCAL_VER"
	[ -n "$xray_LOCAL_DATE" ] && dbus set ss_basic_xray_date="$xray_LOCAL_DATE"
	echo_date "xray二进制文件替换成功... "
}

start_xray(){
	echo_date "开启xray进程... "
	cd /koolshare/bin
	export GOGC=30
	xray run -config=/koolshare/ss/v2ray.json >/dev/null 2>&1 &
	
	local i=10
	until [ -n "$XRAYPID" ]
	do
		i=$(($i-1))
		XRAYPID=`pidof xray`
		if [ "$i" -lt 1 ];then
			echo_date "xray进程启动失败！"
			close_in_five
		fi
		sleep 1
	done
	echo_date xray启动成功，pid：$XRAYPID
}

close_in_five(){
	echo_date "插件将在5秒后自动关闭！！"
	sleep 1
	echo_date 5
	sleep 1
	echo_date 4
	sleep 1
	echo_date 3
	sleep 1
	echo_date 2
	sleep 1
	echo_date 1
	sleep 1
	echo_date 0
	dbus set ss_basic_enable="0"
	#disable_ss >/dev/null
	#echo_date "插件已关闭！！"
	#echo_date ======================= 梅林固件 - 【科学上网】 ========================
	#unset_lock
	exit
}

echo_date "==================================================================="
echo_date "                xray程序更新(Shell by sadog)"
echo_date "==================================================================="
get_latest_version
echo_date "==================================================================="