#!/bin/bash

IP_PREFIX=192.168.1
IP_NETWORK=${IP_PREFIX}.0/24
IP_ARPA=1.168.192
SERVER_IP=17
DOMAIN=lab.home
DNS_HOSTNAME=infra

yum -y install bind bind-utils
systemctl enable named
systemctl start named
systemctl status named
sed -i -e 's/listen-on/#listen-on/g' /etc/named.conf
sed -i -e 's|allow-query     { localhost; }|allow-query     { localhost;'"${IP_NETWORK}"'; }|g' /etc/named.conf

sed -i -e 's|include "/etc/named.rfc1912.zones";|zone "'"${DOMAIN}"'" IN { \
        type master; \
        file "fwd.'"${DOMAIN}"'.db"; \
        allow-update { none; }; \
}; \
 \
zone "'"${IP_ARPA}"'.in-addr.arpa" IN { \
        type master; \
        file "'"${IP_ARPA}"'.db"; \
        allow-update { none; }; \
}; \
 \
include "/etc/named.rfc1912.zones";|g' /etc/named.conf

sed -i -e 's|session-keyfile "/run/named/session.key";|session-keyfile "/run/named/session.key"; \
 \
        forwarders { \
                     8.8.8.8; \
                     8.8.4.4; \
                   };|g' /etc/named.conf

cat <<EOT > /var/named/fwd.${DOMAIN}.db
\$TTL 86400
@               IN      SOA     ${DNS_HOSTNAME}.${DOMAIN}. admin.${DOMAIN}. (
2016042112 ;Serial
3600 ;Refresh
1800 ;Retry
604800 ;Expire
43200 ;Minimum TTL
)

;Name Server Information
@               IN      NS      infra.${DOMAIN}.

;IP address of Name Server
${DNS_HOSTNAME}           IN      A       ${IP_PREFIX}.${SERVER_IP}

;A - Record HostName To Ip Address
repository      IN      A       ${IP_PREFIX}.19
rhevm           IN      A       ${IP_PREFIX}.18

;CNAME record
;ftp            IN      CNAME   rhevm.${DOMAIN}.
EOT

cat <<EOT >> /var/named/${IP_ARPA}.db
\$TTL 86400
@               IN      SOA     ${DNS_HOSTNAME}.${DOMAIN}. admin.${DOMAIN}. (
2014112511 ;Serial
3600 ;Refresh
1800 ;Retry
604800 ;Expire
86400 ;Minimum TTL
)
;Name Server Information
@              IN       NS      ${DNS_HOSTNAME}.${DOMAIN}.

;Reverse lookup for Name Server
${SERVER_IP}             IN       PTR     ${DNS_HOSTNAME}.${DOMAIN}.

;PTR Record IP address to HostName
19             IN       PTR     repository.${DOMAIN}.
18             IN       PTR     rhevm.${DOMAIN}.
EOT

chmod 777 /var/named/fwd.${DOMAIN}.db 
chmod 777 /var/named/${IP_ARPA}.db
systemctl restart named.service

firewall-cmd --zone=public --add-port=53/tcp --permanent
firewall-cmd --zone=public --add-port=53/udp --permanent
firewall-cmd --reload
