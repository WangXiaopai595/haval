#!/bin/bash
# 获取本机公网 IP 地址
IP=$(curl -s "https://ipinfo.io/ip" | tr -d '\n')
echo "当前 IP 是：$IP"
# 检查当前 IP 是否正确
read -p "请确认 IP 是否正确(y/n)：" confirm

while [[ ! "$confirm" =~ ^(y|Y|n|N)$ ]]; do
    read -p "请确认 IP 是否正确(y/n)：" confirm
done

if [[ "$confirm" =~ ^(y|Y|)$ ]]; then
    echo "IP 验证成功，继续下一步。"
else
    # 手动输入 IP
    read -p "请输入正确的 IP 地址：" IP

    while [[ ! $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; do
        echo "请输入正确的 IP 地址！"
        read -p "请输入正确的 IP 地址：" IP
    done

    echo "IP 验证成功，继续下一步。"
fi

# 默认的工程文件下载地址
apk_url="https://github.com/WangXiaopai595/hafu/blob/main/gongcheng.apk"

echo "内置工程模式地址，会将app拉取到nginx的html中,"
read -p "是否需要修改工程模式下载地址：(y/n)" confirm


# 如果选择自定义下载地址
if [[ "$confirm" = "y" || "$confirm" = "Y" ]]; then
    # 给出一个推荐的下载地址供用户参考
    read -p "请输入自定义的下载地址：" apk_url
fi

# 判断系统发行版本
if [ -f "/usr/bin/yum" ] && [ -d "/etc/yum.repos.d" ]; then
	PM="yum"
elif [ -f "/usr/bin/apt-get" ] && [ -f "/usr/bin/dpkg" ]; then
	PM="apt-get"
fi

# 安装 dnsmasq
systemctl stop systemd-resolved > /dev/null 2>&1
echo "开始安装dnsmasq"
if [[ $(systemctl is-active dnsmasq) != "active" ]]; then
    echo "正在安装 dnsmasq ..."
    $PM -y install dnsmasq > /dev/null 2>&1
    systemctl start dnsmasq

    if [[ $(systemctl is-active dnsmasq) != "active" ]]; then
        echo "安装 dnsmasq 失败，请检查网络和配置。"
        exit 1
    fi

    systemctl enable dnsmasq > /dev/null 2>&1
    echo "dnsmasq 安装成功。"
else
    echo "dnsmasq 已经安装，跳过安装步骤。"
fi

# 安装 nginx
if [[ $(systemctl is-active nginx) != "active" ]]; then
    echo "正在安装 nginx ..."
	$PM -y install epel-release > /dev/null 2>&1
    $PM -y install nginx > /dev/null 2>&1
    mkdir /etc/nginx/cert

    systemctl start nginx

    if [[ $(systemctl is-active nginx) != "active" ]]; then
        echo "安装 nginx 失败，请检查网络和配置。"
        exit 1
    fi

    systemctl enable nginx > /dev/null 2>&1
    echo "nginx 已经安装并启动成功。"
else
    echo "nginx 已经安装，跳过安装步骤。"
fi


# 生成 SSL 证书
openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=MyOrg/OU=MyUnit/CN=$IP" \
  -keyout /etc/nginx/cert/server.key -out /etc/nginx/cert/server.crt > /dev/null 2>&1

# 配置 hosts
echo "解析地址hosts"
cat << EOF > /etc/hosts
$IP dzsms.gwm.com.cn
EOF
addr=$(ip route | awk '/default/ {print $5}')

echo "解析地址"
cat << EOF > /etc/dnsmasq.conf
address=/qq.com/$IP
listen-address=$IP
# resolv-file=/etc/dnsmasq.resolv.conf
# addn-hosts=/etc/dnsmasq.hosts
interface=$addr
log-queries
EOF

# if [ $? -eq 0 ]; then
# 	echo "host写入成功"
# else
# 	echo "host写入失败，请手动写入"
# fi
systemctl restart dnsmasq

# 配置 nginx
cat << EOF > /etc/nginx/nginx.conf
worker_processes 1;
events {
  worker_connections 1024;
}
http {
	include mime.types;
	default_type application/octet-stream;
	sendfile on;
	keepalive_timeout 65;
	server {
		listen 443 ssl;
		listen 80;
		server_name $IP;  # 替换为你的域名(或 IP 地址)
		ssl_certificate /etc/nginx/cert/server.crt;
		ssl_certificate_key /etc/nginx/cert/server.key;
		ssl_session_timeout 5m;
		ssl_ciphers HIGH:!aNULL:!MD5;
		ssl_prefer_server_ciphers on;
	 
		location / {
			root /usr/share/nginx/html/;
			index index.html index.htm;
		}

		location /apiv2/car_apk_update {
			default_type application/json;
			return 200 '{
				"code": 200,
				"message": "\u67e5\u8be2\u6210\u529f",
				"data": {
					"apk_version": "99999",
					"apk_url": "https://$IP/gongcheng.apk",
					"apk_msg": "恭喜成功",
					"isUpdate": "Yes",
					"apk_forceUpdate": "Yes",
					"notice": {
						"vin_notice": [
							"VIN码可以在仪表板左上方（前风挡玻璃后面）和车辆铭牌上获得。",
							"本应用适用于2019年及之后生产的车型。"
						],
						"add_notice": [
							"制造年月可通过车辆铭牌获得。",
							"本应用适用于2019年及之后生产的车型。"
						]
					},
					"notice_en": {
						"vin_notice": [

						],
						"add_notice": [
							"The date can be obtained from the certification label."
						]
					}
				}
			}';
		}

	}
}
EOF

if [ $? -eq 0 ]; then
	echo "nginx配置写入成功"
else
	echo "nginx配置写入失败，请手动写入"
fi

# 检查是否安装了 curl 或 wget
if ! type curl >/dev/null 2>&1 && ! type wget >/dev/null 2>&1; then
	$PM -y install wget curl > /dev/null 2>&1
fi

# 下载文件
if type curl >/dev/null 2>&1; then
    # 使用 curl 下载
    curl -sSfLo /usr/share/nginx/html/gongcheng.apk $apk_url
elif type wget >/dev/null 2>&1; then
    # 使用 wget 下载
    wget -q $apk_url -P /usr/share/nginx/html/gongcheng.apk
fi
systemctl restart nginx

if [ $? -eq 0 ]; then
	echo "nginx启动成功，DNS搭建成功，你的DNS是$IP,两部手机A 和B ，A 开热点，B 连上A 开的热点，修改WiFi 设置里面的DNS 地址为上面这个，然后B再开热点，车机连B手机的热点，然后打开智能手册应该就会安装工程模式了"
	echo "也可以笔记本电脑修改hosts，将域名dzsms.gwm.com.cn指向dns服务器，车机连笔记本的热点，然后打开智能手册应该就会安装工程模式了"
	echo "手机热点成功率比较低，建议用笔记本"
else
	echo "nginx启动失败，请检查配置文件"
fi


