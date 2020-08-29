#!/bin/ash

/openvpn/sbin/openvpn --mktun --dev tun0
nft -f /etc/nftables.conf
/openvpn/sbin/openvpn "$@"