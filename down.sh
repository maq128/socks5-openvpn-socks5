#!/bin/sh

/etc/openvpn/down.sh
kill $(cat /var/run/sockd.pid)
