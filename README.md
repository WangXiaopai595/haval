# 介绍
哈弗汽车，安波福车机工程模式、自定义安装软件、dns服务器搭建、高德地图升级

# 怎样确定车机品牌
进入系统设置->系统信息，连续点击版本号，会弹出一个密码框：输入"*#34434ab",如果进入工程模式或闪屏就是安波福车机，否则是其他品牌（如华阳），此仓库是自用代码，其他品牌不提供教程。

# linux搭建dns
在centos中（ubuntu自行修改脚本），使用项目中install.sh开始搭建环境。
如果系统中存在nginx，那么自行根据以下修改nginx配置
`先生成证书：openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj "/C=CN/ST=Beijing/L=Beijing/O=MyOrg/OU=MyUnit/CN=你的IP地址" -keyout /usr/local/nginx/cert/server.key -out /usr/local/nginx/cert/server.crt`

```
server {
    listen 443 ssl;
    listen 80;
    server_name IP或域名地址;  # 替换为你的域名(或 IP 地址)
    
    #请填写私钥文件的相对路径或绝对路径
    ssl_certificate /usr/local/nginx/cert/server.crt; 
    ssl_certificate_key /usr/local/nginx/cert/server.key;
    ssl_session_timeout 5m;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
 
    location / {
        root /usr/local/nginx/html/;
        index index.html index.htm;
    }

    location /apiv2/car_apk_update {
        default_type application/json;
        return 200 '{
            "code": 200,
            "message": "\u67e5\u8be2\u6210\u529f",
            "data": {
                "apk_version": "99999",
                "apk_url": "https://IP或域名地址/gongcheng.apk",
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
```
完成配置后重启nginx即可。

# windows搭建
详细的不说了，和linux类似，修改hosts、然后用虚拟机、apache、nginx或iis达成类似目的即可

# 开始安装工程模式
1. （成功率较低，不推荐）关闭车机的热点和蓝牙，准备2台手机，一台能同时连接wifi和开热点，A手机打开热点，B手机连接A手机热点，B手机在wifi中修改网络信息，把DNS改成自己DNS服务器的IP地址，车机连接B手机热点，然后打开智能手册应该就会安装工程模式了
2. 笔记本修改hosts，将dzsms.gwm.com.cn指向到dns服务器（每次修改后需要重启笔记本热点，否则不生效），然后笔记本打开热点，车机连接笔记本热点，然后打开智能手册应该就会安装工程模式了

# 升级车机高德
安卓需要安装软件：在此[链接](https://www.123pan.com/s/tinSVv-smvWh.html)链接中自行下载，如果链接失效，自行网上找Termux软件安装。
苹果安装软件：ISH SELL

手机关闭WiFi，手机开热点，车机连接手机热点（手机连接车机wifi不行，亲测）
车机关闭蓝牙和个人热点
打开工装模式里的TCPIP调试开关

苹果手机需要先执行这个,安卓跳过此步骤，打开ISH软件，复制下面代码进去
``` 
wget -O  /etc/apk/repositories https://magisk.proyy.com/tmp/ish/ish.tmp ; apk update ; apk add curl bash
```

（安卓、苹果）按回车键等待出现OK，再复制下面进去
```
curl -o install.sh https://magisk.proyy.com/tmp/install.sh ; bash install.sh
```
然后按需要输入对应数字即可升级。

应用市场安装：
安波福主机执行上述命令后，输入5，按回车键
再输202，按回车键等待下载


# 软件合集链接
https://www.123pan.com/s/tinSVv-2aVsh.html

上面教程出自：[kinghisky/hafu](https://github.com/kinghisky/hafu)
再结合本人试错和哈弗益达的公开教程整合而来