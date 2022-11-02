#!/usr/bin/bash

if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root";
	exit 1
fi

#----------------------------------
# Detecting the Architecture
#----------------------------------

if ([ `uname -i` == x86_64 ] || [ `uname -m` == x86_64 ]); then
	ARCH=64
else
	ARCH=32
fi

rpm -Uvh http://download.fedoraproject.org/pub/epel/beta/7/x86_64/epel-release-7-1.noarch.rpm
yum -y install ppp pptpd

cp /etc/pptpd.conf /etc/pptpd.conf.bak
cat >/etc/pptpd.conf<<EOF
option /etc/ppp/options.pptpd
logwtmp
localip 10.0.10.1
remoteip 10.0.10.2-254
EOF

cp /etc/ppp/options.pptpd /etc/ppp/options.pptpd.bak
cat >/etc/ppp/options.pptpd<<EOF
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
proxyarp
lock
nobsdcomp
novj
novjccomp
nologfd
ms-dns 8.8.8.8
ms-dns 8.8.4.4
EOF

cp /etc/ppp/chap-secrets /etc/ppp/chap-secrets.bak
cat >/etc/ppp/chap-secrets<<EOF
USERNAME pptpd PASSWORD *
EOF

cp /etc/sysctl.conf /etc/sysctl.conf.bak
cat >/etc/sysctl.conf<<EOF
net.core.wmem_max = 12582912
net.core.rmem_max = 12582912
net.ipv4.tcp_rmem = 10240 87380 12582912
net.ipv4.tcp_wmem = 10240 87380 12582912
net.core.wmem_max = 12582912
net.core.rmem_max = 12582912
net.ipv4.tcp_rmem = 10240 87380 12582912
net.ipv4.tcp_wmem = 10240 87380 12582912
net.core.wmem_max = 12582912
net.core.rmem_max = 12582912
net.ipv4.tcp_rmem = 10240 87380 12582912
net.ipv4.tcp_wmem = 10240 87380 12582912
net.ipv4.ip_forward = 1
EOF
sysctl -p


chmod +x /etc/rc.d/rc.local
echo "iptables -t nat -A POSTROUTING -s 10.0.10.0/24 -o eth0 -j MASQUERADE" >> /etc/rc.d/rc.local
iptables -t nat -A POSTROUTING -s 10.0.10.0/24 -o eth0 -j MASQUERADE

systemctl start pptpd
systemctl enable pptpd.service
