################################################
#  Install OpenNebula on CentOS 7              #
#  Robert Watkins                              #
#  Updated: 08/18/2019                         #
#  Changelog:                                  #
#  - 1.0: Initial Creation                     #
#  - 1.1: Cleaned Up Output                    #
#  - 1.2: Enabled Firewalld                    #
################################################

#!/bin/bash

# Check if user is root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

clear
echo "##########################################################################################";
echo " _______  _______  _______  __    _  __    _  _______  _______  __   __  ___      _______ ";
echo "|       ||       ||       ||  |  | ||  |  | ||       ||  _    ||  | |  ||   |    |   _   |";
echo "|   _   ||    _  ||    ___||   |_| ||   |_| ||    ___|| |_|   ||  | |  ||   |    |  |_|  |";
echo "|  | |  ||   |_| ||   |___ |       ||       ||   |___ |       ||  |_|  ||   |    |       |";
echo "|  |_|  ||    ___||    ___||  _    ||  _    ||    ___||  _   | |       ||   |___ |       |";
echo "|       ||   |    |   |___ | | |   || | |   ||   |___ | |_|   ||       ||       ||   _   |";
echo "|_______||___|    |_______||_|  |__||_|  |__||_______||_______||_______||_______||__| |__|";
echo "Installer v1.2 "
echo "##########################################################################################";

echo "This might take a while."
if [ -z "$PASS"]; then
    read -sp "For now lets set the oneadmin password: " PASS
    echo " "
fi
echo "Now we wait..."
echo -ne "Progress [#          ]\r"

# Disable Selinux
sed -i "s/SELINUX=.*/SELINUX=disabled/" /etc/selinux/config
setenforce 0
echo -ne "Progress [##         ]\r"

# Adding OpenNebula Repo
cat << EOF > /etc/yum.repos.d/opennebula.repo
[opennebula]
name=opennebula
baseurl=https://downloads.opennebula.org/repo/5.8/CentOS/7/x86_64
enabled=1
gpgkey=https://downloads.opennebula.org/repo/repo.key
gpgcheck=1
#repo_gpgcheck=1

EOF
echo -ne "Progress [###        ]\r"

# Add EPEL Repo and Update
yum -y install wget > /dev/null 2>&1
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm > /dev/null 2>&1
yum install -y ./epel-release-latest-7.noarch.rpm > /dev/null 2>&1
rm ./epel-release-latest-7.noarch.rpm
yum -y update > /dev/null 2>&1
echo -ne "Progress [####       ]\r"

# Install OpenNebula Front End Packages
yum -y install opennebula-server opennebula-sunstone opennebula-ruby opennebula-gate opennebula-flow expect > /dev/null 2>&1
echo -ne "Progress [######     ]\r"

# Ruby Runtime Installation...The long way.
cat << EOF > dumb.exp
#!/usr/bin/expect
set timeout -1
spawn /bin/ruby /usr/share/one/install_gems
expect "1. CentOS/RedHat/Scientific"
send "1\r"
expect "Press enter to continue..."
send " \r"
expect "Is this ok \\\\\[y/d/N\\\\\]:"
send "y\r"
expect "Press enter to continue..."
send "\r"
expect "Abort."
puts "Ended expect script."

EOF
chmod +x dumb.exp
./dumb.exp > /dev/null 2>&1
rm dumb.exp > /dev/null 2>&1
echo -ne "Progress [#######    ]\r"

# TODO - Enable Mysql/Mariadb for proper deployment

# Allow port 9869 in firewalld
systemctl enable firewalld > /dev/null 2>&1
systemctl start firewalld > /dev/null 2>&1
firewall-cmd --zone=public --add-port=9869/tcp --permanent > /dev/null 2>&1
firewall-cmd --reload > /dev/null 2>&1
echo -ne "Progress [########   ]\r"

# Set Password for oneadmin
echo "oneadmin:$PASS" > /var/lib/one/.one/one_auth
echo -ne "Progress [#########  ]\r"

# Enable and Start opennebula and opennebula-sunstone
systemctl enable opennebula > /dev/null 2>&1
systemctl enable opennebula-sunstone > /dev/null 2>&1
echo -ne "Progress [########## ]\r"
systemctl start opennebula
systemctl start opennebula-sunstone
echo -ne "Progress [###########]\r"
echo ""
echo ""
IP="$(ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/')"
echo "The Web Interface can be accessed at: http://$IP:9869"
exit 0
