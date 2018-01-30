#!/bin/bash

# -----------------------------------------
#
# nf_conntrack.sh settings update script
#
# Copyright (c) Paul Taylor 2018
# github.com/bao7uo
# @bao7uo
#
# -----------------------------------------
#
# Helps to prevent nat/conntrack tables
# filling up, especially useful when
# using nmap, Nessus etc on a machine
# with nf_conntrack e.g. iptables/nftables.
# 
# Alters the live configuration and
# makes the new settings persist reboots
#
# -----------------------------------------


# ------------------------
# Configuration/parameters
# ------------------------

SYSCTL_CONF=/etc/sysctl.d/nf_conntrack.conf
MODPROBE_CONF=/etc/modprobe.d/nf_conntrack.conf

# The following values are suggested, it is
# advisable to determine optimal
# environment-specific settings

HASHSIZE_VALUE=196608

declare -A NFC_VALUE=(
  [tcp_timeout_syn_sent]=30
  [tcp_timeout_syn_recv]=30
  [tcp_timeout_fin_wait]=30
  [tcp_timeout_close_wait]=15
  [tcp_timeout_last_ack]=15
  [tcp_timeout_time_wait]=30
  [tcp_timeout_close]=10
  [tcp_timeout_unacknowledged]=30
  [tcp_timeout_established]=3600
  [tcp_timeout_max_retrans]=30
  [udp_timeout]=20
  [udp_timeout_stream]=60
  [icmp_timeout]=15
  [generic_timeout]=60
  [max]=655350
  [buckets]=163840
)

# ---------
# main code 
# ---------

function replace_entry { # remove (if file exists) then append
  [ -f $2 ] && sed -i "/$1/d" $2
  echo $3 >> $2
}

function nf_ct_sysctl_write { # update live value and replace stored values
  NFC_PARAM="net.netfilter.nf_conntrack_$1"
  SYSCTL_RESULT=$(sysctl -w $NFC_PARAM=$2)
  [ $? -eq 0 ] && replace_entry $NFC_PARAM $SYSCTL_CONF "$SYSCTL_RESULT"
}

function nf_ct_update { # iterate over array to update values
  for PARAM in ${!NFC_VALUE[@]}; do
    nf_ct_sysctl_write $PARAM ${NFC_VALUE[$PARAM]} 
  done
}

function hashsize_update { # update live value and replace stored values
  HASHSIZE_LIVE=/sys/module/nf_conntrack/parameters/hashsize
  echo $HASHSIZE_VALUE > $HASHSIZE_LIVE
  HASHSIZE_OPTION='options ip_conntrack hashsize'
  replace_entry "$HASHSIZE_OPTION" $MODPROBE_CONF "$HASHSIZE_OPTION=$HASHSIZE_VALUE"
}

nf_ct_update
hashsize_update

