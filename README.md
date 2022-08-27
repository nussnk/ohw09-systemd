# Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig).

Создадим таймер
logwatcher.timer 
```
[Unit]
Description=Run a logwatch service every 30 seconds

[Timer]
# Run every 30 secs
OnUnitActiveSec=30

[Install]
WantedBy=multi-user.target
```
Создадим сервис
logwatcher.service
```
[Unit]
Description=My logwatcher service

[Service]
Type=oneshot
EnvironmentFile=-/etc/logwatcher/env
ExecStart=/opt/logwatcher.sh $WORD $LOG

[Install]
WantedBy=multi-user.target
```
Создадим скрипт, который будет проверять наличие слова в лог файле
```
#!/bin/bash

word=$1
logfile=$2
curdate=`date`

logger "logwatcher is up and running"
logger "looking for the word $1 in $2 file"

if grep $word $logfile &> /dev/null
then
        logger "$curdate: I found the word!"
else
        exit 0
fi
```
создадим файл env, где зададим слово и путь к лог файлу
```
#Configuration file for the logwatcher service

WORD="ALERT"
LOG=/var/log/logwatcher.log
```

создадим logwatcher.log файл, в котором будем рандомный текст со словом "ALERT"
создадим скрипт systemd-01.sh, который расположит файлы в нужные места, запустит таймер, а также сервис в первый раз (это необходимо, поскольку таймер отсчитывает время от предыдущего запуска)

```
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
```

# Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi).

Создадим скрипт systemd-02.sh, который
1. Установит нужные пакеты spawn-fcgi php php-cli mod_fcgid httpd
2. В файле /etc/sysconfig/spawn-fcgi раскоментирует строки SOCKET и OPTIONS
3. Скопирует сервис spawn-fcgi.service в нужную папку
```
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
```
Собственно скрипт:
```
#!/bin/bash

yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y

sed 's/#S/S/' /etc/sysconfig/spawn-fcgi | sed 's/#O/O/' | tee -i /etc/sysconfig/spawn-fcgi
cp /vagrant/systemd-02/spawn-fcgi.service /etc/systemd/system/
systemctl start spawn-fcgi
systemctl status spawn-fcgi
```
# Дополнить unit-файл httpd (он же apache) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.

Создадим скрипт, который 
1. Для того, чтобы была возможность запускать несколько инстансов сервиса httpd, нужно создать шаблон. Изначально его нет, создадим путем копирования основоного сервиса, добавив @ в имя сервиса - cp /lib/systemd/system/httpd{,@}.service
2. Добавим -%I к EnvironmentFile
3. Создадим EnvironmentFile для двух инстансов httpd-first и httpd-second, указав в них параметры запуска httpd сервиса с определенными конфигами
4. Создадим эти конфиги, поменяв во втором Listen порт на 8080 и изменив PidFile
5. Запускаем два сервиса
```
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
```

# Provisioning
Создадим файл для провиженинга
Он запустит все три скрипта поочереди
проверим результат выполнения
```
Aug 27 22:54:10 localhost systemd: Starting My logwatcher service...
Aug 27 22:54:10 localhost root: logwatcher is up and running
Aug 27 22:54:10 localhost root: looking for the word ALERT in /var/log/logwatcher.log file
Aug 27 22:54:10 localhost root: Sat Aug 27 22:54:10 UTC 2022: I found the word!
Aug 27 22:54:10 localhost systemd: Started My logwatcher service.
Aug 27 22:54:33 localhost systemd: Created slice User Slice of vagrant.
Aug 27 22:54:33 localhost systemd: Started Session 4 of user vagrant.
Aug 27 22:54:33 localhost systemd-logind: New session 4 of user vagrant.
Aug 27 22:54:40 localhost systemd: Starting My logwatcher service...
Aug 27 22:54:41 localhost root: logwatcher is up and running
Aug 27 22:54:41 localhost root: looking for the word ALERT in /var/log/logwatcher.log file
Aug 27 22:54:41 localhost root: Sat Aug 27 22:54:41 UTC 2022: I found the word!
Aug 27 22:54:41 localhost systemd: Started My logwatcher service.
```
```
[root@localhost ~]# systemctl status spawn-fcgi.service
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Sat 2022-08-27 22:53:41 UTC; 2min 8s ago
 Main PID: 2440 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─2440 /usr/bin/php-cgi
           ├─2444 /usr/bin/php-cgi
           ├─2445 /usr/bin/php-cgi
           ├─2446 /usr/bin/php-cgi
           ├─2447 /usr/bin/php-cgi
           ├─2448 /usr/bin/php-cgi
           ├─2449 /usr/bin/php-cgi
           ├─2450 /usr/bin/php-cgi
           ├─2451 /usr/bin/php-cgi
           ├─2452 /usr/bin/php-cgi
           ├─2453 /usr/bin/php-cgi
           ├─2454 /usr/bin/php-cgi
           ├─2455 /usr/bin/php-cgi
           ├─2456 /usr/bin/php-cgi
           ├─2457 /usr/bin/php-cgi
           ├─2458 /usr/bin/php-cgi
           ├─2459 /usr/bin/php-cgi
           ├─2462 /usr/bin/php-cgi
           ├─2463 /usr/bin/php-cgi
           ├─2464 /usr/bin/php-cgi
           ├─2465 /usr/bin/php-cgi
           ├─2466 /usr/bin/php-cgi
           ├─2467 /usr/bin/php-cgi
           ├─2468 /usr/bin/php-cgi
           ├─2469 /usr/bin/php-cgi
           ├─2470 /usr/bin/php-cgi
           ├─2471 /usr/bin/php-cgi
           ├─2472 /usr/bin/php-cgi
           ├─2473 /usr/bin/php-cgi
           ├─2474 /usr/bin/php-cgi
           ├─2476 /usr/bin/php-cgi
           ├─2477 /usr/bin/php-cgi
           └─2478 /usr/bin/php-cgi
```
```
[root@localhost ~]# ss -tpln
State      Recv-Q Send-Q Local Address:Port               Peer Address:Port           
LISTEN     0      128          [::]:8080                     [::]:*                   users:(("httpd",pid=2502,fd=4),("httpd",pid=2501,fd=4),("httpd",pid=2500,fd=4),("httpd",pid=2499,fd=4),("httpd",pid=2498,fd=4),("httpd",pid=2497,fd=4),("httpd",pid=2496,fd=4))
LISTEN     0      128          [::]:80                       [::]:*                   users:(("httpd",pid=2494,fd=4),("httpd",pid=2493,fd=4),("httpd",pid=2492,fd=4),("httpd",pid=2491,fd=4),("httpd",pid=2490,fd=4),("httpd",pid=2489,fd=4),("httpd",pid=2488,fd=4))
```
