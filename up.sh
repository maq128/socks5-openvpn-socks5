#!/bin/sh

/etc/openvpn/up.sh
sockd -D -f /sos/sockd.conf
