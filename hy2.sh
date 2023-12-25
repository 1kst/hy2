#!/bin/bash


if [ "$EUID" -ne 0 ]; then
    echo "请以root权限运行此脚本"
    exit 1
fi


cat >docker-compose.yaml <<EOL
version: "3.9"
services:
  hysteria:
    image: ghcr.io/cedar2025/hysteria:latest
    container_name: hysteria
    restart: always
    network_mode: "host"
    volumes:
      - acme:/acme
      - ./hysteria.yaml:/etc/hysteria.yaml
      - ./tls/cert.crt:/etc/hysteria/tls.crt
      - ./tls/private.key:/etc/hysteria/tls.key
    command: ["server", "-c", "/etc/hysteria.yaml"]
volumes:
  acme:
EOL

echo "Step 2: 生成docker-compose.yaml文件"


mkdir -p tls
echo "Step 3: 创建tls文件夹"


cat >tls/cert.crt <<EOL
-----BEGIN CERTIFICATE-----
MIIBhTCCASugAwIBAgIULZesiB1OQVPUdf2JN7EAnlU9muEwCgYIKoZIzj0EAwIw
FzEVMBMGA1UEAwwMd3d3LmJpbmcuY29tMCAXDTIzMTIyMDEzNTg1NFoYDzIxMjMx
MTI2MTM1ODU0WjAXMRUwEwYDVQQDDAx3d3cuYmluZy5jb20wWTATBgcqhkjOPQIB
BggqhkjOPQMBBwNCAAR2mN9VUpNdVI6gTmSNN+4++bj4LrTBFuMb4Gnc2PiQMPbD
oLj5D19YGXMuiJHJ4B9RcMrnTRqh+oakKJBJ0qWJo1MwUTAdBgNVHQ4EFgQUx35x
vIJc7W//19aGeI52elNQY44wHwYDVR0jBBgwFoAUx35xvIJc7W//19aGeI52elNQ
Y44wDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAgNIADBFAiBxftetbhlG0dPx
7WKQS2O/sY7xE00vdC93ytynXP1bhQIhAOD5agmh+CVs/bt92D/j73oWNCQ/gnas
/FDT2AOc0E6w
-----END CERTIFICATE-----
EOL

echo "Step 4: 在tls目录下生成cert.crt文件"


cat >tls/private.key <<EOL
-----BEGIN EC PARAMETERS-----
BggqhkjOPQMBBw==
-----END EC PARAMETERS-----
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEILTPK3y8jUsoxtD9xdKATHYwBsXvdMa17KQWijrZWTjmoAoGCCqGSM49
AwEHoUQDQgAEdpjfVVKTXVSOoE5kjTfuPvm4+C60wRbjG+Bp3Nj4kDD2w6C4+Q9f
WBlzLoiRyeAfUXDK500aofqGpCiQSdKliQ==
-----END EC PRIVATE KEY-----
EOL

echo "Step 5: 在tls目录下生成private.key文件"


read -p "Step 7: 请输入面板地址(带https://): " panelHost
read -p "Step 8: 请输入面板节点密钥: " apiKey
read -p "Step 9: 请输入Hysteria节点ID: " nodeID
read -p "Step 10: 请输入流量监听端口 (默认7653): " listenPort
listenPort=${listenPort:-7653}
read -p "Step 11: 是否禁用UDP？(y/n): " disableUDP

cat >hysteria.yaml <<EOL
v2board:
  apiHost: $panelHost
  apiKey: $apiKey
  nodeID: $nodeID
tls:
  type: tls
  cert: /etc/hysteria/tls.crt
  key: /etc/hysteria/tls.key
auth:
  type: v2board
trafficStats:
  listen: 127.0.0.1:$listenPort
acl: 
  inline: 
    - reject(10.0.0.0/8)
    - reject(172.16.0.0/12)
    - reject(192.168.0.0/16)
    - reject(127.0.0.0/8)
    - reject(fc00::/7)
disableUDP: $([[ "$disableUDP" == "y" ]] && echo "true" || echo "false")
EOL

echo "Step 6: 生成hysteria.yaml文件"
echo "Step 12: 正在尝试启动docker"
chmod 777 docker-compose.yaml
chmod 777 hysteria.yaml
docker-compose up -d
echo -e "\e[33m1、请自行运行命令docker-compose logs验证是否成功启动docker"
echo "2、目前使用默认tls配置(微软自签证书)，请保证面板前端节点sni设置为www.bing.com"
echo "3、若要使用自定义域名sni，请替换'/脚本所在目录/tls'文件夹下的证书文件并在脚本所在目录执行以下命令重新部署后端"
echo "docker-compose down"
echo "docker-compose up -d"
echo "执行以下命令查看是否报错"
echo "docker-compose logs\e[0m"
