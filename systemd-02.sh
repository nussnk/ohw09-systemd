#!/bin/bash

yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y
sed 's/#S/S/' /etc/sysconfig/spawn-fcgi | sed 's/#O/O/' | tee -i /etc/sysconfig/spawn-fcgi
cp /vagrant/systemd-02/spawn-fcgi.service /etc/systemd/system/
systemctl start spawn-fcgi
systemctl status spawn-fcgi

