################################################
#  Install OpenNebula Node on CentOS 7         #
#  Robert Watkins                              #
#  Updated: 08/18/2019                         #
#  Changelog:                                  #
#  - 1.0: Initial Creation                     #
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
echo "Node Installer v1.0 "
echo "##########################################################################################";

echo "This might also take a while."
if [ -z "$PASS"]; then
    read -sp "For now lets set the oneadmin password: " PASS
    echo " "
fi
echo "Now we wait..."

echo -ne "Progress [=         ]\r"

# Disable Selinux
sed -i "s/SELINUX=.*/SELINUX=disabled/" /etc/selinux/config
setenforce 0
echo -ne "Progress [==        ]\r"

# Adding OpenNebula Repo
cat << EOT > /etc/yum.repos.d/opennebula.repo
[opennebula]
name=opennebula
baseurl=https://downloads.opennebula.org/repo/5.8/CentOS/7/x86_64
enabled=1
gpgkey=https://downloads.opennebula.org/repo/repo.key
gpgcheck=1
#repo_gpgcheck=1

EOT
echo -ne "Progress [===       ]\r"

# Update and Install Packages
sudo makecache fast > /dev/null 2>&1
sudo yum -y update > /dev/null 2>&1
echo -ne "Progress [======    ]\r"
yum -y install opennebula-node-kvm > /dev/null 2>&1
yum install -y centos-release-qemu-ev > /dev/null 2>&1
echo -ne "Progress [========  ]\r"
yum install -y qemu-kvm-ev > /dev/null 2>&1
echo -ne "Progress [========= ]\r"

# Configure Libvirtd
sed -i "/unix_sock_group =/d" /etc/libvirt/libvirtd.conf
sed -i "/unix_sock_rw_perms =/d" /etc/libvirt/libvirtd.conf
echo "unix_sock_group = \"oneadmin\"" >> /etc/libvirt/libvirtd.conf
echo "unix_sock_rw_perms = \"0777\"" >> /etc/libvirt/libvirtd.conf
systemctl restart libvirtd > /dev/null 2>&1

# Set Password for oneadmin
echo -e "$PASS\n$PASS" | passwd oneadmin > /dev/null 2>&1

echo -ne "Progress [==========]\n"
echo "Done!"
echo "Now you have to connect them. Good luck!"

exit 0
