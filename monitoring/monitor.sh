#!/bin/bash

#gets directory where the script is executed from, regardless of the working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/../lib/lib.sh

MIN_DISK_SPACE=300 #in MB
LIVE_SITE_PATH="/var/www/deployment-project"
LIVE_DATABASE_NAME="ror_test2"
LIVE_SITE_URL="http://local.deployment.com"
LOG_DIR="/var/logs"
LOG_FILE="$($LIB getUniqueName log)/.log"
LOG_TEMP="$LOG_DIR/temp"

DBUSER="root"
DBPWD="password"

PRODUCTION_SERVER_IP="192.168.0.33"
PRODUCTION_USER="testuser"
PRODUCTION_PWD="password"

#0=don't send, 1=send
SEND_EMAIL=0

#create log directory if doesn't exist
if [ ! -d $LOG_TEMP ]
then
	mkdir $LOG_TEMP -p
fi

#check enough space available
spaceAvailable=$($LIB getAvailableDiskSpace /var/www)
if [ $spaceAvailable -lt $MIN_DISK_SPACE ];
then
	echo "Low disk space"	
	SEND_EMAIL=1
fi

#check apache runs
apacheRunning=$(ps -ef | grep "apache2" | wc -l)
if [ "$apacheRunning" = "0" ]
then
	echo "Apache not running"
	SEND_EMAIL=1
fi

#check mysql runs
mysqlRunning=$(ps -ef | grep "mysqld" | wc -l)
if [ "$mysqlRunning" = "0" ]
then
	echo "MySQL not running"
	SEND_EMAIL=1
fi

cd $LOG_TEMP
#check site is reponsive
wget -q $LIVE_SITE_URL
if [ ! -f "index.html" ]
then
	#file not found, must be due to some error. 
	echo "Test page download failed."
	SEND_EMAIL=1
fi

#check load average
loadAverage=$(uptime | awk -F'[a-z]:' '{ print $2}' | awk -F',' '{ print $3}')
if [ $loadAverage -gt 8.0 ]
then
	echo "Load average very high. Current value: $loadAverage"
	SEND_EMAIL=1
fi

#send email if some things go over the limit
if [ $SEND_EMAIL -eq 1 ]
then
	echo "Sending email"
fi

#log everything to /var/logs
