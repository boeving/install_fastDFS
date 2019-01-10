#!/bin/bash

read -p "setup hostip: " hostip
echo $hostip

#if [ "$hostip" == '' ];then
#  hostnamectl set-hostname "${hostip}"
#fi
read -p "setup tracker http.server_port: " tracker_http_port
echo ${tracker_http_port}

read -p "setup storage path: " store_path
echo ${store_path}

read -p "setup log path: " base_path
echo ${base_path}

read -p "setup group name: " group_name
echo ${group_name}

# 1.基本依赖
yum install -y gcc gcc-c++ zlib zlib-devel openssl openssl-devel libpng-devel gtk2-devel glib-devel git

# 2.
tar -xf libfastcommon-master.tar.gz
tar -xf fastdfs-V5.11.tar.gz
#tar -xf fastdfs-nginx-module.tar.gz


mkdir -p ${store_path}/data
ln -s ${store_path}/data ${store_path}/M00
mkdir -p ${base_path}

#  disable SELinux
if [ `getenforce` != 'disabled' ];then
  setenforce 0
  sed -i s#SELINUX=enforcing#SELINUX=disabled#g /etc/selinux/config
fi
if [ ! `grep "SELINUX=disabled" /etc/selinux/config` ];then
  echo "eng"
fi

# 2 firewall
systemctl restart firewalld;
firewall-cmd --add-port=22122/tcp --permanent;
firewall-cmd --add-port=23000/tcp --permanent;
firewall-cmd --reload;

# 3.
cd libfastcommon-master
./make.sh
./make.sh install
cd ../

sed -i 's#/usr/local/bin/#/usr/bin/#g' fastdfs-5.11/init.d/fdfs_storaged
sed -i 's#/usr/local/bin/#/usr/bin/#g' fastdfs-5.11/init.d/fdfs_trackerd
cd fastdfs-5.11
./make.sh
./make.sh install
cd ../

cp config/client.conf /etc/fdfs/client.conf
cp config/storage.conf /etc/fdfs/storage.conf
cp config/tracker.conf /etc/fdfs/tracker.conf
cp fastdfs-5.11/conf/http.conf /etc/fdfs/.
cp fastdfs-5.11/conf/mime.types /etc/fdfs/.


ln -s /usr/bin/fdfs_trackerd /usr/local/bin/.
ln -s /usr/bin/stop.sh /usr/local/bin/.
ln -s /usr/bin/restart.sh /usr/local/bin/.
ln -s /usr/bin/fdfs_storaged /usr/local/bin/.


# 4. config 

sed -i 's#base_path=/home/yuqing/fastdfs#base_path='${base_path}'#g' /etc/fdfs/tracker.conf
sed -i 's#http.server_port=8080#http.server_port='${tracker_http_port}'#g' /etc/fdfs/tracker.conf

sed -i 's#group_name=group1#group_name='${group_name}'#g' /etc/fdfs/storage.conf
sed -i 's#base_path=/home/yuqing/fastdfs#base_path='${base_path}'#g' /etc/fdfs/storage.conf
sed -i 's#store_path0=/home/yuqing/fastdfs#store_path0='${store_path}'#g' /etc/fdfs/storage.conf
sed -i 's#tracker_server=192.168.209.121:22122#tracker_server='${hostip}':22122#g' /etc/fdfs/storage.conf

sed -i 's#base_path=/home/yuqing/fastdfs#base_path='${base_path}'#g' /etc/fdfs/client.conf
sed -i 's#store_path0=/home/yuqing/fastdfs#store_path0='${store_path}'#g' /etc/fdfs/client.conf
sed -i 's#tracker_server=192.168.0.197:22122#tracker_server='${hostip}':22122#g' /etc/fdfs/client.conf
sed -i 's#http.tracker_server_port=80#http.tracker_server_port='${tracker_http_port}'#g' /etc/fdfs/client.conf

# 5.
service fdfs_trackerd start 
echo "service fdfs_trackerd start" >> /etc/rc.local

service fdfs_storaged start 
echo "service fdfs_storage start" >> /etc/rc.d/rc.local

# 6. test 
#/usr/bin/fdfs_monitor /etc/fdfs/storage.conf
# ehco "ok fds" >> /root/mytest.txt
# /usr/bin/fdfs_upload_file /etc/fdfs/client.conf /root/mytest.txt 

#####
