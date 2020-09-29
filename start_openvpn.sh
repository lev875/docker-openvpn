#!/bin/ash

/sbin/openvpn --mktun --dev tun0
nft -f /etc/nftables.conf
/sbin/openvpn "$@"