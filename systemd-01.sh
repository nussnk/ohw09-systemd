#!/bin/bash

# copying a timer
cp /vagrant/systemd-01/logwatcher.timer /etc/systemd/system/

# copying a service
cp /vagrant/systemd-01/logwatcher.service /etc/systemd/system/ 

# copying a script
cp /vagrant/systemd-01/logwatcher.sh /opt/

# make it executable
chmod +x /opt/logwatcher.sh

# copying a folder for an EnvironmentFile
mkdir /etc/logwatcher

# copying the EnvironmentFile
cp /vagrant/systemd-01/env /etc/logwatcher/

# copying a log file
cp /vagrant/systemd-01/logwatcher.log /var/log/

# starting the timer
systemctl start logwatcher.timer

# starting the service 
systemctl start logwatcher.service
