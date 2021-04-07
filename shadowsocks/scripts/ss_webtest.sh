#!/bin/sh

# shadowsocks script for AM380 merlin firmware
# by sadog (sadoneli@gmail.com) from koolshare.cn

source /koolshare/scripts/base.sh
eval `dbus export ssconf_basic`

# flush previous test value in the table
webtest=`dbus list ssconf_basic_webtest_ | sort -n -t "_" -k 4|cut -d "=" -f 1`
if [ ! -z "$webtest" ];then
	for line in $webtest
	do
		dbus remove "$line"
	done
fi

get_function_switch() {
	case "$1" in
		0)
			echo "false"
		;;
		1)
			echo "true"
		;;
	esac
}

get_ws_header() {
	if [ -n "$1" ];then
		echo {\"Host\": \"$1\"}
	else
		echo "null"
	fi
}

get_h2_host() {
	if [ -n "$1" ];then
		echo [\"$1\"]
	else
		echo "null"
	fi
}

get_path(){
	if [ -n "$1" ];then
		echo \"$1\"
	else
		echo "null"
	fi
}

create_v2ray_json(){

rm -rf /tmp/tmp_v2ray.json

		local kcp="null"
		local tcp="null"
		local ws="null"
		local h2="null"
		local tls="null"
		local xtls="null"
		local vless_flow=""

		# tcp和kcp下tlsSettings为null，ws和h2下tlsSettings
		[ -z "$(eval echo \$ssconf_basic_v2ray_mux_concurrency_$nu)" ] && local ssconf_basic_v2ray_mux_concurrency=8
		[ "$(eval echo \$ssconf_basic_v2ray_network_security_$nu)" == "none" ] && local ssconf_basic_v2ray_network_security=""
		
		if [ "$(eval echo \$ssconf_basic_v2ray_network_$nu)" == "ws" -o "$(eval echo \$ssconf_basic_v2ray_network_$nu)" == "h2" ] && [ -z "$(eval echo \$ssconf_basic_v2ray_network_tlshost_$nu)" ] && [ -n "$(eval echo \$ssconf_basic_v2ray_network_host_$nu)" ]; then
		 	local ssconf_basic_v2ray_network_tlshost_$nu="$(eval echo \$ssconf_basic_v2ray_network_host_$nu)"
		fi

		case "$(eval echo \$ssconf_basic_v2ray_network_security_$nu)" in
		tls)
			local tls="{
					\"allowInsecure\": true,
					\"serverName\": \"$(eval echo \ssconf_basic_v2ray_network_tlshost_$nu)\"
					}"
			;;
		xtls)
			local xtls="{
					\"serverName\": \"$(eval echo \$ssconf_basic_v2ray_network_tlshost_$nu)\"
					}"
			local vless_flow="\"flow\": \"$(eval echo \$ssconf_basic_v2ray_network_flow_$nu)\","
			;;
		*)
			local tls="null"
			local xtls="null"
			;;
		esac
		#fi
		# incase multi-domain input
		if [ "$(eval echo \$ssconf_basic_v2ray_network_host_$nu | grep ",")" ]; then
			ssconf_basic_v2ray_network_host_$nu=$(eval echo \$ssconf_basic_v2ray_network_host_$nu | sed 's/,/", "/g')
		fi

		case "$(eval echo \$ssconf_basic_v2ray_network_$nu)" in
		tcp)
			if [ "$(eval echo \$ssconf_basic_v2ray_headtype_tcp_$nu)" == "http" ]; then
				local tcp="{
					\"connectionReuse\": true,
					\"header\": {
					\"type\": \"http\",
					\"request\": {
					\"version\": \"1.1\",
					\"method\": \"GET\",
					\"path\": [\"/\"],
					\"headers\": {
					\"Host\": [\"$(eval echo \$ssconf_basic_v2ray_network_host_$nu)\"],
					\"User-Agent\": [\"Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.75 Safari/537.36\",\"Mozilla/5.0 (iPhone; CPU iPhone OS 10_0_2 like Mac OS X) AppleWebKit/601.1 (KHTML, like Gecko) CriOS/53.0.2785.109 Mobile/14A456 Safari/601.1.46\"],
					\"Accept-Encoding\": [\"gzip, deflate\"],
					\"Connection\": [\"keep-alive\"],
					\"Pragma\": \"no-cache\"
					}
					},
					\"response\": {
					\"version\": \"1.1\",
					\"status\": \"200\",
					\"reason\": \"OK\",
					\"headers\": {
					\"Content-Type\": [\"application/octet-stream\",\"video/mpeg\"],
					\"Transfer-Encoding\": [\"chunked\"],
					\"Connection\": [\"keep-alive\"],
					\"Pragma\": \"no-cache\"
					}
					}
					}
					}"
			else
				local tcp="null"
			fi
			;;
		kcp)
			local kcp="{
				\"mtu\": 1350,
				\"tti\": 50,
				\"uplinkCapacity\": 12,
				\"downlinkCapacity\": 100,
				\"congestion\": false,
				\"readBufferSize\": 2,
				\"writeBufferSize\": 2,
				\"header\": {
				\"type\": \"$(eval echo \$ssconf_basic_v2ray_headtype_kcp_$nu)\",
				\"request\": null,
				\"response\": null
				}
				}"
			;;
		ws)
		local local_path=$(eval echo \$ssconf_basic_v2ray_network_path_$nu)
		local local_header=$(eval echo \$ssconf_basic_v2ray_network_host_$nu)
			local ws="{
				\"connectionReuse\": true,
				\"path\": $(get_path $local path),
				\"headers\": $(get_ws_header local_header)
				}"
			;;
		h2)
		local local_path=$(eval echo \$ssconf_basic_v2ray_network_path_$nu)
		local local_header=$(eval echo \$ssconf_basic_v2ray_network_host_$nu)
			local h2="{
				\"path\": $(get_path $local_path),
				\"host\": $(get_h2_host $local_header)
				}"
			;;
		esac
		# log area
		cat >"/tmp/tmp_v2ray.json" <<-EOF
			{
			"log": {
				"access": "/dev/null",
				"error": "/tmp/v2ray_log.log",
				"loglevel": "error"
			},
		EOF
			# inbounds area (23458 for socks5)
			cat >>"/tmp/tmp_v2ray.json" <<-EOF
				"inbounds": [
					{
						"port": 23458,
						"listen": "0.0.0.0",
						"protocol": "socks",
						"settings": {
							"auth": "noauth",
							"udp": true,
							"ip": "127.0.0.1",
							"clients": null
						},
						"streamSettings": null
					},
					{
						"listen": "0.0.0.0",
						"port": 3335,
						"protocol": "dokodemo-door",
						"settings": {
							"network": "tcp,udp",
							"followRedirect": true
						}
					}
				],
			EOF
		# outbounds area
		if [ "$array13" == "vmess" ]; then
			cat >>"/tmp/tmp_v2ray.json" <<-EOF
				"outbounds": [
				  {
					"tag": "agentout",
					"protocol": "vmess",
					"settings": {
					  "vnext": [
						{
						  "address": "$(dbus get ssconf_basic_server_$nu)",
						  "port": $(eval echo \$ssconf_basic_port_$nu),
						  "users": [
							{
							  "id": "$(eval echo \$ssconf_basic_v2ray_uuid_$nu)",
							  "alterId": $(eval echo \$ssconf_basic_v2ray_alterid_$nu),
							  "security": "$(eval echo \$ssconf_basic_v2ray_security_$nu)"
							}
						  ]
						}
					  ],
					  "servers": null
					},
					"streamSettings": {
					  "network": "$(eval echo \$ssconf_basic_v2ray_network_$nu)",
					  "security": "$(eval echo \$ssconf_basic_v2ray_network_security_$nu)",
					  "tlsSettings": $tls,
					  "tcpSettings": $tcp,
					  "kcpSettings": $kcp,
					  "wsSettings": $ws,
					  "httpSettings": $h2
					},
					"mux": {
					  "enabled": $(get_function_switch $(eval echo \$ssconf_basic_v2ray_mux_enable_$nu)),
					  "concurrency": $ssconf_basic_v2ray_mux_concurrency
					}
				  }
				]
				}
			EOF
		elif [ "$array13" == "vless" ]; then
		  #vless
		  cat >>"/tmp/tmp_v2ray.json" <<-EOF
				"outbounds": [
				  {
					"tag": "agentout",
					"protocol": "vless",
					"settings": {
					  "vnext": [
						{
						  "address": "$(dbus get ssconf_basic_server_$nu)",
						  "port": $(eval echo \$ssconf_basic_port_$nu),
						  "users": [
							{
							  "id": "$(eval echo \$ssconf_basic_v2ray_uuid_$nu)",
							  "level": 1,
							  $vless_flow
							  "encryption": "none"
							}
						  ]
						}
					  ],
					  "servers": null
					},
					"streamSettings": {
					  "network": "$(eval echo \$ssconf_basic_v2ray_network_$nu)",
					  "security": "$(eval echo \$ssconf_basic_v2ray_network_security_$nu)",
					  "tlsSettings": $tls,
					  "xtlsSettings": $xtls,
					  "tcpSettings": $tcp,
					  "kcpSettings": $kcp,
					  "wsSettings": $ws,
					  "httpSettings": $h2
					},
					"mux": {
					  "enabled": $(get_function_switch $(eval echo \$ssconf_basic_v2ray_mux_enable_$nu)),
					  "concurrency": $ssconf_basic_v2ray_mux_concurrency
					}
				  }
				]
				}
			EOF
		fi
		
}

create_trojan_json(){
rm -rf /tmp/tmp_v2ray.json

		 #trojan
		 # inbounds area (23458 for socks5)  
		cat > /tmp/tmp_v2ray.json <<-EOF
		{
			"log": {
				"access": "/dev/null",
				"error": "/tmp/v2ray_log.log",
				"loglevel": "error"
			},
				"inbounds": [
					{
						"port": 23458,
						"listen": "0.0.0.0",
						"protocol": "socks",
						"settings": {
							"auth": "noauth",
							"udp": true,
							"ip": "127.0.0.1",
							"clients": null
						},
						"streamSettings": null
					},
					{
						"listen": "0.0.0.0",
						"port": 3335,
						"protocol": "dokodemo-door",
						"settings": {
							"network": "tcp,udp",
							"followRedirect": true
						}
					}
				],
			"outbounds": [
			  {
				"protocol": "trojan",
				"settings": {
				  "servers": [
					{
					  "address": "$array1",
					  "port": $array2,
					  "password": "$array3"
					}
				  ]
				},
				"streamSettings": {
				  "network": "tcp",
				  "security": "tls",
				  "tlsSettings": {
                    "serverName": "$(eval echo \$ssconf_basic_trojan_sni_$nu)"
                }
				}
			  }
			]
		}
		EOF
}

start_webtest(){
	array1=`dbus get ssconf_basic_server_$nu`
	array2=`dbus get ssconf_basic_port_$nu`
	array3=`dbus get ssconf_basic_password_$nu|base64_decode`
	array4=`dbus get ssconf_basic_method_$nu`
	array5=`dbus get ssconf_basic_use_rss_$nu`
	#array6=`dbus get ssconf_basic_onetime_auth_$nu`
	array7=`dbus get ssconf_basic_rss_protocol_$nu`
	array8=`dbus get ssconf_basic_rss_obfs_$nu`
	array9=`dbus get ssconf_basic_ss_v2ray_plugin_$nu`
	array10=`dbus get ssconf_basic_ss_v2ray_plugin_opts_$nu`
	array11=`dbus get ssconf_basic_mode_$nu`
	array12=`dbus get ssconf_basic_type_$nu`	
	array13=`dbus get ssconf_basic_v2ray_protocol_$nu`
	
	if [ "$array10" != "" ];then
		if [ "$array9" == "1" ];then
			ARG_V2RAY_PLUGIN="--plugin v2ray-plugin --plugin-opts $array10"
		else
			ARG_V2RAY_PLUGIN=""
		fi
	fi
	
	if [ "$array11" == "1" ] || [ "$array11" == "2" ] || [ "$array11" == "3" ] || [ "$array11" == "5" ];then
		if [ "$array12" == "1" ];then   #ssr
			cat > /tmp/tmp_ss.json <<-EOF
			{
			    "server":"$array1",
			    "server_port":$array2,
			    "local_port":23458,
			    "password":"$array3",
			    "timeout":600,
			    "protocol":"$array7",
			    "obfs":"$array8",
			    "obfs_param":"",
			    "method":"$array4"
			}
		EOF
			rss-local -b 0.0.0.0 -l 23458 -c /tmp/tmp_ss.json -u -f /var/run/sslocal2.pid >/dev/null 2>&1
			sleep 3
			result=`curl -o /dev/null -s -w %{time_total}:%{speed_download} --connect-timeout 15 --socks5-hostname 127.0.0.1:23458 $ssconf_basic_test_domain`
			# result=`curl -o /dev/null -s -w %{time_connect}:%{time_starttransfer}:%{time_total}:%{speed_download} --socks5-hostname 127.0.0.1:23458 https://www.google.com/`
			sleep 1
			dbus set ssconf_basic_webtest_$nu=$result
			kill -9 `ps|grep rss-local|grep 23458|awk '{print $1}'` >/dev/null 2>&1
			rm -rf /tmp/tmp_ss.json
		elif [ "$array12" == "0" ];then   #ss
			ss-local -b 0.0.0.0 -l 23458 -s $array1 -p $array2 -k $array3 -m $array4 -u $ARG_OTA $ARG_V2RAY_PLUGIN -f /var/run/sslocal3.pid >/dev/null 2>&1
			sleep 3
			result=`curl -o /dev/null -s -w %{time_total}:%{speed_download} --connect-timeout 15 --socks5-hostname 127.0.0.1:23458 $ssconf_basic_test_domain`
			sleep 1
			dbus set ssconf_basic_webtest_$nu=$result
			kill -9 `ps|grep ss-local|grep 23458|awk '{print $1}'` >/dev/null 2>&1
			
		elif [ "$array12" == "3" ];then   #v2ray
			create_v2ray_json 
			xray run -config=/tmp/tmp_v2ray.json >/dev/null 2>&1 &
			sleep 3
			result=`curl -o /dev/null -s -w %{time_total}:%{speed_download} --connect-timeout 15 --socks5-hostname 127.0.0.1:23458 $ssconf_basic_test_domain`
			sleep 1
			dbus set ssconf_basic_webtest_$nu=$result
			kill -9 `ps|grep xray|grep 'tmp_v2ray'|awk '{print $1}'` >/dev/null 2>&1	
			rm -rf /tmp/tmp_v2ray.json
			
		elif [ "$array12" == "4" ];then   #trojan
			create_trojan_json 
			xray run -config=/tmp/tmp_v2ray.json >/dev/null 2>&1 &
			sleep 3
			result=`curl -o /dev/null -s -w %{time_total}:%{speed_download} --connect-timeout 15 --socks5-hostname 127.0.0.1:23458 $ssconf_basic_test_domain`
			sleep 1
			dbus set ssconf_basic_webtest_$nu=$result
			kill -9 `ps|grep xray|grep 'tmp_v2ray'|awk '{print $1}'` >/dev/null 2>&1	
			rm -rf /tmp/tmp_v2ray.json				
		fi

	else
		dbus set ssconf_basic_webtest_$nu="failed"
	fi
}

# start testing
if [ "$ssconf_basic_test_node" != "0" ];then
	nu="$ssconf_basic_test_node"
	start_webtest
else
	server_nu=`dbus list ssconf_basic_server | sort -n -t "_" -k 4|cut -d "=" -f 1|cut -d "_" -f 4`
	for nu in $server_nu
	do
		start_webtest
	done
fi
