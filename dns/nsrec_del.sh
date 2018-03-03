#!/bin/bash

IP_PREFIX=192.168.1
IP_ARPA=1.168.192
DOMAIN=lab.home

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -i|--ip)
    IP="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--hostname)
    HOSTNAME="$2"
    shift # past argument
    shift # past value
    ;;
    -d|--domainname)
    DOMAIN="$2" # optional
    shift # past argument
    shift # past value
    ;;
    -p|--prefix)
    IP_PREFIX="$2" # optional
    shift # past argument
    shift # past value
    ;;
    -a|--arpa)
    IP_ARPA="$2" # optional
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ "x${IP}" = "x" ] && [ "x${HOSTNAME}" = "x" ]; then
  echo "You need to provide at least one of IP or Hostname";
  exit(1);
elif [ "x${HOSTNAME}" = "x" ]; then
  sed -i -e '/ *IN *A *'"${IP_PREFIX}"'\.'"${IP}"'/d' /var/named/fwd.${DOMAIN}.db
  sed -i -e '/'"${IP}"' *IN *PTR.*\.'"${DOMAIN}"'\./d' /var/named/${IP_ARPA}.db
elif [ "x${IP}" = "x" ]; then
  sed -i -e '/'"${HOSTNAME}"' *IN *A *'"${IP_PREFIX}"'\./d' /var/named/fwd.${DOMAIN}.db
  sed -i -e '/ *IN *PTR *'"${HOSTNAME}"'\.'"${DOMAIN}"'\./d' /var/named/${IP_ARPA}.db
else
  sed -i -e '/'"${HOSTNAME}"' *IN *A *'"${IP_PREFIX}"'\.'"${IP}"'/d' /var/named/fwd.${DOMAIN}.db
  sed -i -e '/'"${IP}"' *IN *PTR *'"${HOSTNAME}"'\.'"${DOMAIN}"'\./d' /var/named/${IP_ARPA}.db
fi

