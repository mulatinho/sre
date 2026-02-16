#!/bin/bash
usage() {
	echo "ERR: One or more envs are missing: $1"
	exit 1
}

[ ! "$SSH_PORT" ] && usage "SSH_PORT"

# clean rules
iptables -X
iptables -F
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT

# basic attacks
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
iptables -A INPUT -p tcp --syn -m limit --limit 50/second --limit-burst 100 -j ACCEPT

# enable all lo
iptables -A INPUT -i lo -j ACCEPT

echo ":. dont mess with connections already running"
iptables -A INPUT  -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT


iptables -A INPUT -p tcp --dport $SSH_PORT -m conntrack --ctstate NEW \
	-m recent --set
iptables -A INPUT -p tcp --dport $SSH_PORT -m conntrack --ctstate NEW \
	-m recent --update --seconds 60 --hitcount 10 -j DROP

# enable TCP INPUT
iptables -A INPUT -p tcp -m tcp --dport 25   -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 587  -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 143  -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 993  -j ACCEPT
#iptables -A INPUT -p tcp -m tcp --dport 3000 -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dports 80,443 -m conntrack \
	--ctstate NEW -j ACCEPT
iptables -A INPUT -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW \
	-m recent --update --seconds 60 --hitcount 10 -j DROP

# enable TCP OUTPUT
iptables -A OUTPUT -p tcp --dport 80   -j ACCEPT
iptables -A OUTPUT -p tcp --dport 143  -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443  -j ACCEPT
iptables -A OUTPUT -p tcp --dport $SSH_PORT -j ACCEPT
iptables -A OUTPUT -p tcp --dport 25   -j ACCEPT
iptables -A OUTPUT -p tcp --dport 587  -j ACCEPT
iptables -A OUTPUT -p tcp --dport 1433 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 6667 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 6697 -j ACCEPT

# dns
iptables -A INPUT -p udp -m udp --dport 53 -j ACCEPT # DNS
iptables -A OUTPUT -p udp --dport 53   -j ACCEPT

# log drops
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "IPTables-Dropped: " --log-level 4

# block everything else
iptables -P INPUT DROP
