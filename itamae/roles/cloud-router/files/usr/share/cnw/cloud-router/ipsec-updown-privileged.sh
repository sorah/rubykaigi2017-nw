#!/bin/bash

set -u
set -e
set -x

if [ $# -gt 0 ]; then
  exec env "$@" /usr/share/cnw/cloud-router/ipsec-updown-privileged.sh
fi

PRIMARY_IP="$(grep "^# primary_ip:" /etc/ipsec.conf| head -n1 | cut -d: -f 2)"
PRIMARY_IP_HOST="${PRIMARY_IP%%/*}"
PRIMARY_IP6="$(grep "^# primary_ip6:" /etc/ipsec.conf| head -n1 | cut -d: -f 2)"
PRIMARY_IP6_HOST="${PRIMARY_IP%%/*}"

VTI_IFNAME="$(grep "^conn ${PLUTO_CONNECTION}" /etc/ipsec.conf|sed -r 's/^.*#.*ifname=([^,]+?)(,.+$|$)/\1/')"
if [ -n "${VTI_IFNAME}" ]; then 
  VTI_IF="vti_${VTI_IFNAME}"
else
  VTI_IF="vti${PLUTO_UNIQUEID}"
fi

case "${PLUTO_VERB}" in
  up-client|up-client-v6)
    if ip link show dev "${VTI_IF}" >/dev/null; then
      exit 0
    fi

    if [ "${PLUTO_VERB}" = "up-client-v6" ] || echo "${PLUTO_PEER}" | grep -q ":"; then
      tunnel_mode=vti6
    else
      tunnel_mode=vti
    fi

    ip tunnel add "${VTI_IF}" \
      local "${PLUTO_ME}" remote "${PLUTO_PEER}" mode "${tunnel_mode}" \
      okey "${PLUTO_MARK_OUT%%/*}" ikey "${PLUTO_MARK_IN%%/*}"

    ip link set "${VTI_IF}" up

    VTI_LOCALIP="$(grep "^conn ${PLUTO_CONNECTION}" /etc/ipsec.conf|sed -r 's/^.*#.*leftinner=([^,]+?)(,.+$|$)/\1/')"
    if [ -n "${VTI_LOCALIP}" ]; then
      ip addr add "${VTI_LOCALIP}" dev "${VTI_IF}"
    fi
    VTI_LOCALIP6="$(grep "^conn ${PLUTO_CONNECTION}" /etc/ipsec.conf|sed -r 's/^.*#.*leftinner6=([^,]+?)(,.+$|$)/\1/')"
    if [ -n "${VTI_LOCALIP6}" ]; then
      ip addr add "${VTI_LOCALIP6}" dev "${VTI_IF}"
    fi

    # if [ -n "${PRIMARY_IP_HOST}" ]; then
    #   ip addr add "${PRIMARY_IP_HOST}" dev "${VTI_IF}"
    # fi

    VTI_REMOTEIP="$(grep "^conn ${PLUTO_CONNECTION}" /etc/ipsec.conf|sed -r 's/^.*#.*rightinner=([^,]+?)(,.+$|$)/\1/')"
    if [ -n "${VTI_REMOTEIP}" ]; then
      VTI_STATICROUTES="$(grep "^conn ${PLUTO_CONNECTION}" /etc/ipsec.conf|sed -r 's/^.*#.*staticroute=([^,]+?)(,.+$|$)/\1/')"

      if [ -n "${PRIMARY_IP_HOST}" ]; then
        srcip="${PRIMARY_IP_HOST%%/*}"
      else
        srcip="${VTI_LOCALIP%%/*}"
      fi

      remoteip="${VTI_REMOTEIP%%/*}"

      if [ -n "${VTI_STATICROUTES}" ]; then
        for dest in $VTI_STATICROUTES; do
          ip route add "${dest}" via "${remoteip}" src "${srcip}" || :
        done
      fi
    fi

    VTI_REMOTEIP6="$(grep "^conn ${PLUTO_CONNECTION}" /etc/ipsec.conf|sed -r 's/^.*#.*rightinner6=([^,]+?)(,.+$|$)/\1/')"
    if [ -n "${VTI_REMOTEIP6}" ]; then
      VTI_STATICROUTES6="$(grep "^conn ${PLUTO_CONNECTION}" /etc/ipsec.conf|sed -r 's/^.*#.*staticroute6=([^,]+?)(,.+$|$)/\1/')"

      if [ -n "${PRIMARY_IP6_HOST}" ]; then
        srcip="${PRIMARY_IP6_HOST%%/*}"
      else
        srcip="${VTI_LOCALIP6%%/*}"
      fi

      remoteip="${VTI_REMOTEIP6%%/*}"

      if [ -n "${VTI_STATICROUTES6}" ]; then
        for dest in $VTI_STATICROUTES6; do
          ip route add "${dest}" via "${remoteip}" src "${srcip}" || :
        done
      fi
    fi

    sysctl -w "net.ipv4.conf.${VTI_IF}.disable_policy=1"
    sysctl -w "net.ipv4.conf.${VTI_IF}.forwarding=1"
    sysctl -w "net.ipv4.conf.${VTI_IF}.rp_filter=2"
    sysctl -w "net.ipv6.conf.${VTI_IF}.forwarding=1"
    ;;
  down-client|down-client-v6)
    if [ -z "${VTI_IFNAME}" ]; then 
      ip tunnel del "${VTI_IF}"
    fi
    ;;
esac

# XXX:
iptables -t mangle -F
