# 项目说明

本项目的目标是，不仅要翻墙，而且要能方便地改变访问互联网的出口 IP 地址。

- 最基本的 SOCKS5 代理服务器

架设一个 SOCKS5 代理服务器有多种方法，如果已经有一台可以 ssh 登录的服务器，那么最简单的办法就是利用 ssh
的端口转发功能建立一个 SOCKS5 代理。这样只要购买一台境外的云主机，就可以翻墙了。

    --> SOCKS5(ssh client) --> 境外云主机(ssh server) --> Internet

- 有时候需要改变访问互联网的出口 IP

用 ssh 的方法建立的 SOCKS5 代理，访问互联网时的出口 IP 就是 ssh 登录的服务器的 IP 地址。

有时候这种固定的 IP 地址可能不适用，比如购买的是阿里云在新加坡机房的服务器，一般访问互联网都是没有问题的，
但是当访问 OpenAI API 的时候，对方会把这个 IP 判定为“中国”并拒绝提供服务，这时候就要设法换个更“好”的 IP。

- 使用 VPN Gate 中继服务器

这是由日本国立筑波大学运作的一个学术实验项目，里面包含了全球很多台中继服务器提供开放的连接服务。

这些中继服务器可以接受多种形式的客户端连接，本项目采用了 OpenVPN client。

[在列表中选择一个合适的中继服务器](https://www.vpngate.net/cn/)，下载其 OpenVPN 配置文件，就可以通过 OpenVPN client 建立与其的连接了。

然而，由于墙的原因，这些中继服务器大部分都是无法直接访问的，逐个尝试非常麻烦，好在我们已经有了一个可以翻墙的
SOCKS5 代理，可以让 OpenVPN client 通过这个 SOCKS5 代理连接到中继服务器。

- 通道有了，如何使用

OpenVPN 是一个 VPN 软件，如果直接在宿主环境下安装 OpenVPN client，它将接管整个系统的网络通信，需要通过精细化的配置，
才能区分出哪些目标走代理，哪些不走代理，有时候这样很方便，但如果是在一台日常工作的电脑上的话这样反倒很麻烦了，
因为通常只有某些特定的软件或者特定的目标需要通过代理来访问。

本项目采用的方案是，在一个 docker 容器里运行 OpenVPN client，同时在其基础上架设一个 SOCKS5 服务器（dante）并暴露给宿主环境。

    --> SOCKS5(dante) --> OpenVPN client --> SOCKS5(ssh) --> 境外云主机(ssh server) --> VPN Gate 中继服务器 --> Internet

# 构建和使用

## 构建 docker image
```cmd
docker build -t sos .
```

## 启动 docker 容器

在 Windows 的 Docker Desktop 环境下：
```cmd
docker run ^
  --name sos ^
  -d ^
  --cap-add=NET_ADMIN ^
  --device /dev/net/tun ^
  -p 7080:1080 ^
  -v "%CD%:/sos" ^
  sos ^
  --data-ciphers "AES-128-CBC:AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305" ^
  --config /sos/client.ovpn ^
  --auth-nocache ^
  --socks-proxy 192.168.1.99 7070 ^
  --script-security 2 ^
  --up /sos/up.sh ^
  --down /sos/down.sh
```
其中 `socks-proxy` 指向的是已有的 SOCKS5 代理服务。

## 使用 SOCKS5 代理

docker 容器启动后，将在 docker 宿主机的 7080 端口提供 SOCKS5 代理服务，出口 IP 则是所连接的 VPN Gate 中继服务器的地址。

## 测试代理连接的有效性

```sh
curl "https://ip.cn/api/index?type=0"
curl --socks5-hostname 127.0.0.1:7080 "https://ip.cn/api/index?type=0"

curl ifconfig.co
curl --socks5-hostname 127.0.0.1:7080 ifconfig.co
```

# 文件说明

- client.ovpn: OpenVPN client 配置文件，从 [VPN Gate 中继服务器列表](https://www.vpngate.net/cn/) 下载得到。
- Dockerfile: docker 镜像描述文件。
- sockd.conf: dante 配置文件。
- up.sh: OpenVPN 连接成功后执行的脚本，做了两件事：①调整 DNS 设置；②启动 dante 服务。
- down.sh: OpenVPN 连接断开后执行的脚本，做了两件事：①恢复 DNS 设置；②关闭 dante 服务。

# 参考资料

[openvpn manual](https://manpages.ubuntu.com/manpages/kinetic/en/man8/openvpn.8.html)

[VPN Gate 中继服务器列表](https://www.vpngate.net/cn/)
