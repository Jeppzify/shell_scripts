#!/bin/sh

# Created for Debian-based machines.
# Script to get a quick overview of a host.
# Checks what the machine is running, users with uid +1000, ip, open ports and services (if possible).
# Output format is heavily inspired by yaml and, for the most part, can be parsed as such.


echo "HOSTNAME: $(hostname)"
echo "OS:"
if [ -f /etc/os-release ]; then
	cat /etc/os-release | grep -i "^name\|_id\|version_c" | tr '="' ': ' | tr -d '"$' | sed "s/^/  /g"
elif [ -f /etc/debian_version ]; then
	echo "  NAME: Debian\n  VERSION_ID:" $(cat /etc/debian_version)
else 
	cat /etc/lsb-release | sed "s/^/  /g"
fi

echo "  ARCH: $(uname -m)"
echo "  KERNEL: $(uname -r)"

if [ -d /usr/lib/systemd ]; then 
	echo "  INIT_SYSTEM: Systemd" 
elif [ -d /usr/share/upstart ]; then
	echo "  INIT_VERSION: Upstart"
else
	echo "  INIT_VERSION: SysV"
fi

echo "USERS:"
for user in $(getent passwd | awk -F : '{print $1,$3}' | grep "10[0-9][0-9]"); do 
	echo $user | grep -v "[[:digit:]]" | sed "s/^/  \- /" 
done

echo "NETWORK:"
echo "  #Interface IPv4"
for i in $(ls -c /sys/class/net | grep "^eth\|^ens\|^enp"); do
	echo "  - $i $(ip addr show dev $i | grep "inet\s" | awk '{print $2}')"
done

if [ $(id -u) = 0 ]; then
	echo "PORTS_AND_SERVICES:\n  #Port Service"
	if [ -f /usr/bin/ss ]; then
		ss -lntp | grep LISTEN | grep -v "127.0." | awk '{print $4,$6}' | sed "s/\"\,.*$//" | sed "s/users:((\"//" | sed -r "s/^.+?\:\:?\]?\:?//" | sort -un | sed "s/^/  - /g"
	else
		netstat -lntp | grep LISTEN | grep -v "127.0." | awk '{print $4,$7}' | sed "s/.*[[:digit:]]\://" | sed "s/\([[:space:]][[:digit:]]*\/\)/ /g" | tr -d ":$" | sort -un | grep -v "\-$" | sed "s/^/  - /g"
	fi
else
	echo "OPEN_PORTS:"
	netstat -lnt | grep LISTEN | grep -v "127.0." | awk '{print $4}' | sed "s/.*[[:digit:]]\://" | grep -v "^:" | sort -n | sed "s/^/  - /g"
fi
