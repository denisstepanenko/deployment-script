#!/bin/bash

#gets directory where the script is executed from, regardless of the working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/../lib/lib.sh

sudo chmod 0755 $LIB

MIN_DISK_SPACE=300 #in MB
LIVE_SITE_PATH="/var/www/deployment-project"
LIVE_DATABASE_NAME="ror_test2"
LIVE_DOMAIN_NAME="local.deployment.com"
LIVE_SITE_URL="http://$LIVE_DOMAIN_NAME"
LOG_DIR="/tmp/logs"
#LOG_FILE="$LOG_DIR/$($LIB getUniqueName log).log"
LOG_FILE="$LOG_DIR/monitor.log"
LOG_TEMP="$LOG_DIR/temp"

DBUSER="root"
DBPWD="password"

PRODUCTION_SERVER_IP="192.168.0.31"
PRODUCTION_USER="testuser"
PRODUCTION_PWD="password"

#0=don't send, 1=send
SEND_EMAIL=0

#add hosts entry for local.deployment.com domain
hostAdded=$(sudo less /etc/hosts | grep "$LIVE_DOMAIN_NAME")		
if [ -z "$hostAdded" ]
then
	sudo echo "$PRODUCTION_SERVER_IP $LIVE_DOMAIN_NAME" >> /etc/hosts 
fi

#create log directory if doesn't exist
if [ ! -d $LOG_TEMP ]
then
	mkdir $LOG_TEMP -p
fi

echo "" >> $LOG_FILE
echo $(date) >> $LOG_FILE

#check sshpass is installed. Needed for FTPing file using SFTP, this utility will enter the password for us.
isSSHpassInstalled=$($LIB checkDependencyInstalled sshpass)
if [ "$isSSHpassInstalled" = "0" ]
then			
	$LIB installDependency sshpass
fi

#sshpass -p$PRODUCTION_PWD ssh -oStrictHostKeyChecking=no $PRODUCTION_USER@$PRODUCTION_SERVER_IP mkdir $remoteScriptDir -p
#sshpass -p$PRODUCTION_PWD ssh -oStrictHostKeyChecking=no $PRODUCTION_USER@$PRODUCTION_SERVER_IP 'bash -s'

#check enough space available
spaceAvailable=$(sshpass -p$PRODUCTION_PWD ssh -oStrictHostKeyChecking=no $PRODUCTION_USER@$PRODUCTION_SERVER_IP df /var -m -P | grep /dev | cut -b 36-46 | tr -d ' ')
if [ $spaceAvailable -lt $MIN_DISK_SPACE ];
then
	echo "Low disk space" >> $LOG_FILE
	SEND_EMAIL=1
fi

#check apache runs
apacheRunning=$(sshpass -p$PRODUCTION_PWD ssh -oStrictHostKeyChecking=no $PRODUCTION_USER@$PRODUCTION_SERVER_IP ps -ef | grep apache2 | grep -v grep | wc -l)
if [ "$apacheRunning" = "0" ]
then
	echo "Apache not running" >> $LOG_FILE
	SEND_EMAIL=1
fi

#check mysql runs
mysqlRunning=$(sshpass -p$PRODUCTION_PWD ssh -oStrictHostKeyChecking=no $PRODUCTION_USER@$PRODUCTION_SERVER_IP ps -ef | grep "mysqld" | grep -v grep | wc -l)
if [ "$mysqlRunning" = "0" ]
then
	echo "MySQL not running" >> $LOG_FILE
	SEND_EMAIL=1
fi

cd $LOG_TEMP
#check site is reponsive
wget -q $LIVE_SITE_URL
if [ ! -f "index.html" ]
then
	#file not found, must be due to some error. 
	echo "Test page download failed." >> $LOG_FILE
	SEND_EMAIL=1
fi

#check load average
loadAverage=$(sshpass -p$PRODUCTION_PWD ssh -oStrictHostKeyChecking=no $PRODUCTION_USER@$PRODUCTION_SERVER_IP uptime | awk -F'[a-z]:' '{ print $2}' | awk -F',' '{ print $3}')
#loadAverage=$(echo $loadAverage | tr -d ' ')
highLoad=$(echo "$loadAverage > 8.0" | bc)
if [ "$highLoad" = "1" ]
then
	echo "Load average very high. Current value: $loadAverage" >> $LOG_FILE
	SEND_EMAIL=1
fi

vmstatResult=$(sshpass -p$PRODUCTION_PWD ssh -oStrictHostKeyChecking=no $PRODUCTION_USER@$PRODUCTION_SERVER_IP vmstat -SM 10 2 | sed -n '4p')
vmstatArr=($vmstatResult)

freeRam=${vmstatArr[3]}
contextSwitches=${vmstatArr[11]}
userTime=${vmstatArr[12]}
kernelTime=${vmstatArr[13]}

#check number of context switches 
if [ $contextSwitches -gt 2000 ]
then
	echo "Context Switches too high: $contextSwitches"
	SEND_EMAIL=1
fi

#amount of free RAM
if [ $freeRam -lt 100 ]
then
	echo "Free RAM is less than 100MB: $freeRam MB"
	SEND_EMAIL=1
fi

#check user time
if [ $userTime -gt 50 ]
then
	echo "User Time is too high: $userTime"
	SEND_EMAIL=1
fi

#check kernel time
if [ $kernelTime -gt 50 ]
then
	echo "Kernel Time is too high: $kernelTime"
	SEND_EMAIL=1
fi



#send email if some things go over the limit
if [ $SEND_EMAIL -eq 1 ]
then
	mail -s "Test Postfix" denis.step.monitor@gmail.com < $LOG_FILE
	#echo $SEND_EMAIL
fi

cat $LOG_FILE
sudo rm -rf $LOG_TEMP
