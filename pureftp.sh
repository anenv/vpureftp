#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

###########################################
#         Centos Install Pureftp          #
#      Intro: http://www.anenv.com        #
#      Author: Anenv(anenv@live.cn)       #
###########################################

clear
echo ""
echo "###########################################"
echo "#         Centos Install Pureftp          #"
echo "#      Intro: http://www.anenv.com        #"
echo "#      Author: Anenv(anenv@live.cn)       #"
echo "###########################################"
echo ""

#Disable SeLinux
if [ -s /etc/selinux/config ]; then
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi

function Install_Pureftpd(){
	echo "Begin Install Pureftpd Service";
	wget --no-check-certificate https://raw.githubusercontent.com/Anenv/vpureftp/master/conf/pure-ftpd-1.0.42.tar.gz
	tar -xzvf pure-ftpd-1.0.42.tar.gz
	cd pure-ftpd-1.0.42
	./configure --prefix=/usr/local/pureftpd CFLAGS=-O2 --with-puredb --with-quotas --with-cookie --with-virtualhosts --with-diraliases --with-sysquotas --with-ratios --with-altlog --with-paranoidmsg --with-shadow --with-welcomemsg --with-throttling --with-uploadscript --with-language=english --with-rfc2640 --with-ftpwho --with-tls
	make && make install

	cp configuration-file/pure-config.pl /usr/local/pureftpd/sbin/
    chmod 755 /usr/local/pureftpd/sbin/pure-config.pl
	
    mkdir /usr/local/pureftpd/etc
	wget --no-check-certificate https://raw.githubusercontent.com/Anenv/vpureftp/master/conf/pure-ftpd.conf -O /usr/local/pureftpd/etc/pure-ftpd.conf
	wget --no-check-certificate https://raw.githubusercontent.com/Anenv/vpureftp/master/conf/pureftpd -O /etc/init.d/pureftpd
    chmod +x /etc/init.d/pureftpd
	
    touch /usr/local/pureftpd/etc/pureftpd.passwd
    touch /usr/local/pureftpd/etc/pureftpd.pdb
	
	cd ../
	rm -rf pure-ftpd-1.0.42
	rm -rf pure-ftpd-1.0.42.tar.gz
	
	if [ -s /sbin/iptables ]; then
        /sbin/iptables -I INPUT 7 -p tcp --dport 20 -j ACCEPT
        /sbin/iptables -I INPUT 8 -p tcp --dport 21 -j ACCEPT
        /sbin/iptables -I INPUT 9 -p tcp --dport 20000:30000 -j ACCEPT
        service iptables save
    fi
	
	if [[ -s /usr/local/pureftpd/sbin/pure-config.pl && -s /usr/local/pureftpd/etc/pure-ftpd.conf && -s /etc/init.d/pureftpd ]]; then
        echo "Starting pureftpd..."
        /etc/init.d/pureftpd start
		chkconfig pureftpd on
        echo "Install Pure-FTPd Completed!"
    else
        Echo_Red "Pureftpd install failed!"
    fi
}

function Uninstall_Pureftpd(){
    echo "Begin Uninstall Pureftpd Service";
    if [ ! -f /usr/local/pureftpd/sbin/pure-config.pl ]; then
        echo "Pureftpd was not installed!"
        exit 1
    fi
    echo "Stop pureftpd..."
    /etc/init.d/pureftpd stop
    echo "Remove service..."
    Remove_StartUp pureftpd
    echo "Delete files..."
    rm -f /etc/init.d/pureftpd
    rm -rf /usr/local/pureftpd
    echo "Pureftpd uninstall completed."
}

function Add_Ftp_User(){
    echo "Begin Add Ftp User..."
    read -p "Enter ftp account name: " ftp_account_name
    if [ "${ftp_account_name}" = "" ]; then
        echo "FTP account name can't be empty!"
        exit 1
    fi
	read -p "Enter password for ftp account ${ftp_account_name}: " ftp_account_password
    if [ "${ftp_account_password}" = "" ]; then
        echo "FTP password can't be empty!"
        exit 1
    fi
    if [ "${vhostdir}" = "" ]; then
        read -p "Enter directory for ftp account ${ftp_account_name}: " vhostdir
        if [ "${vhostdir}" = "" ]; then
            echo "Directory can't be empty!"
            exit 1
        fi
    fi
    www_uid=`id -u www`
    www_gid=`id -g www`
	cat >/tmp/pass${ftp_account_name}<<EOF
${ftp_account_password}
${ftp_account_password}
EOF
	/usr/local/pureftpd/bin/pure-pw useradd ${ftp_account_name} -f /usr/local/pureftpd/etc/pureftpd.passwd -u ${www_uid} -g ${www_gid} -d ${vhostdir} -m < /tmp/pass${ftp_account_name}
    [ $? -eq 0 ] && echo "Created FTP User: ${ftp_account_name} Sucessfully." || echo "FTP User: ${ftp_account_name} already exists!"
	rm -f /tmp/pass${ftp_account_name}

}

function List_Ftp_User(){
    echo "List Ftp User..."
    /usr/local/pureftpd/bin/pure-pw list -f /usr/local/pureftpd/etc/pureftpd.passwd
    [ $? -eq 0 ] && echo "List FTP User Sucessfully." || echo "Read database failed."
}

function Edit_Ftp_User(){
    echo "List Ftp User..."
    /usr/local/pureftpd/bin/pure-pw list -f /usr/local/pureftpd/etc/pureftpd.passwd
    [ $? -eq 0 ] && echo "List FTP User Sucessfully." || echo "Read database failed."
    echo "Edit Ftp User..."
    read -p "Enter ftp account name: " ftp_account_name
    if [ "${ftp_account_name}" = "" ]; then
        echo "FTP account name can't be empty!"
        exit 1
    fi
    read -p "Enter password for ftp account ${ftp_account_name}: " ftp_account_password
    if [ "${ftp_account_password}" != "" ]; then
		cat >/tmp/pass${ftp_account_name}<<EOF
${ftp_account_password}
${ftp_account_password}
EOF
		/usr/local/pureftpd/bin/pure-pw passwd ${ftp_account_name} -f /usr/local/pureftpd/etc/pureftpd.passwd -m < /tmp/pass${ftp_account_name}
		[ $? -eq 0 ] && echo "FTP User: ${ftp_account_name} change password Sucessfully." || echo "FTP User: ${ftp_account_name} change password failed!"
		rm -f /tmp/pass${ftp_account_name}
	else
        echo "FTP password will no change."
    fi
    read -p "Enter directory for ftp account ${ftp_account_name}: " vhostdir
	if [ "${vhostdir}" != "" ]; then
	    www_uid=`id -u www`
		www_gid=`id -g www`
		/usr/local/pureftpd/bin/pure-pw usermod ${ftp_account_name} -f /usr/local/pureftpd/etc/pureftpd.passwd -u ${www_uid} -g ${www_gid} -d ${vhostdir} -m
		[ $? -eq 0 ] && echo "FTP User: ${ftp_account_name} change diretcory Sucessfully." || echo "FTP User: ${ftp_account_name} change directory failed!"
	else
        echo "Directory will no change."
    fi
}

function Del_Ftp_User(){
    echo "List Ftp User..."
    /usr/local/pureftpd/bin/pure-pw list -f /usr/local/pureftpd/etc/pureftpd.passwd
    [ $? -eq 0 ] && echo "List FTP User Sucessfully." || echo "Read database failed."
    echo "Del Ftp User..."
    read -p "Enter ftp account name: " ftp_account_name
    if [ "${ftp_account_name}" = "" ]; then
        echo "FTP account name can't be empty!"
        exit 1
    fi
    echo "Your will delete ftp user ${ftp_account_name}"
    echo "Sleep 10s,Press ctrl+c to cancel..."
    sleep 10
    /usr/local/pureftpd/bin/pure-pw userdel ${ftp_account_name} -f /usr/local/pureftpd/etc/pureftpd.passwd -m
    [ $? -eq 0 ] && echo "FTP User: ${ftp_account_name} deleted Sucessfully." || echo "FTP User: ${ftp_account_name} not exists!"
}

echo "Which do you want to? Input the number."
echo "1. Install Pureftpd Service"
echo "2. Uninstall Pureftpd Service"
echo "3. Add Pureftp User"
echo "4. List Pureftp User"
echo "5. Edit Pureftp User"
echo "6. Del Pureftp User"
read num

case "$num" in
[1] ) (Install_Pureftpd);;
[2] ) (Uninstall_Pureftpd);;
[3] ) (Add_Ftp_User);;
[4] ) (List_Ftp_User);;
[5] ) (Edit_Ftp_User);;
[6] ) (Del_Ftp_User);;
*) echo "Nothing,Exit!";;
esac

