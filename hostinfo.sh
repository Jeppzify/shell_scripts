#!/bin/sh

echo "HOSTNAME: $(hostname)"
echo "OS:"
if [ -f /etc/os-release ]; then
	cat /etc/os-release | grep -i "^name\|_id\|version_c" | tr -d '"' | sed "s/=/: /g" | sed "s/^/  /g"
elif [ -f /etc/debian_version ]; then
	echo "  NAME: Debian"
	echo "  VERSION: " $(cat /etc/debian_version)
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

echo "RESOURCES:"
echo "  CPU: $(cat /proc/cpuinfo | grep ^processor | wc -l)"
echo "  RAM: $($(which free) -h --si | grep Mem | awk '{print $2}')"
if [ $(lsblk | grep ^sd | wc -l) -eq 1 ]; then
        echo "  DISK:$(lsblk --output SIZE -d /dev/sda | grep -v SIZE)"
else
        echo "  DISK:"
        lsblk --output SIZE -d /dev/sd[a-z] | grep -v SIZE | sed "s/^/  - /g"
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
	echo "PORTS_AND_SERVICES:"
	echo "  #Port Service"
	if [ -f $(which ss) ]; then
		ss -lntp | grep LISTEN | grep -v "127.0." | awk '{print $4,$6}' | sed "s/\"\,.*$//" | sed "s/users:((\"//" | sed -r "s/^.+?\:\:?\]?\:?//" | sort -un | sed "s/^/  - /g"
	else
		netstat -lntp | grep LISTEN | grep -v "127.0." | awk '{print $4,$7}' | sed "s/.*[[:digit:]]\://" | sed "s/\([[:space:]][[:digit:]]*\/\)/ /g" | tr -d ":$" | sort -un | grep -v "\-$" | sed "s/^/  - /g"
	fi
else
	echo "OPEN_PORTS:"
	netstat -lnt | grep LISTEN | grep -v "127.0." | awk '{print $4}' | sed "s/.*[[:digit:]]\://" | grep -v "^:" | sort -n | sed "s/^/  - /g"
fi

echo "WEBSITES:"
if [ -d /etc/nginx/sites-enabled ]; then
	grep "\sserver_name" /etc/nginx/sites-enabled/* 2>/dev/null | awk '{print $2}' | tr -d ';' | uniq | sed "s/^/  - /g"
elif [ -d /etc/apache2/sites-enabled ]; then
	grep ServerName /etc/apache2/sites-enabled/* 2>/dev/null | awk '{print $3}' | uniq | sed "s/^/  - /g"
fi
