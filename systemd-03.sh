#!/bin/bash

cp /lib/systemd/system/httpd{,@}.service 
sed 's/sysconfig\/httpd/sysconfig\/httpd-%I/' /lib/systemd/system/httpd@.service | tee /etc/systemd/system/httpd@.service
cp /etc/sysconfig/httpd{,-first}
cp /etc/sysconfig/httpd{,-second}
sed 's/^#OPTIONS=/OPTIONS=-f conf\/first.conf/' /etc/sysconfig/httpd-first | tee -i /etc/sysconfig/httpd-first
sed 's/^#OPTIONS=/OPTIONS=-f conf\/second.conf/' /etc/sysconfig/httpd-second | tee -i /etc/sysconfig/httpd-second
cp /etc/httpd/conf/{httpd,first}.conf
sed 's/^Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf | tee /etc/httpd/conf/second.conf
echo "PidFile /var/run/httpd-second.pid" >> /etc/httpd/conf/second.conf
systemctl start httpd@first
systemctl start httpd@second

