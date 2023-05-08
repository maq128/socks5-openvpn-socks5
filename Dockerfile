FROM alpine:latest

RUN echo http://mirrors.aliyun.com/alpine/latest-stable/main > /etc/apk/repositories \
 && echo http://mirrors.aliyun.com/alpine/latest-stable/community >> /etc/apk/repositories \
 && apk add --update --no-cache openvpn dante-server

WORKDIR /sos

ENTRYPOINT ["openvpn"]
