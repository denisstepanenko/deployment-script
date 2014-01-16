#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/../../lib/lib.sh 

echo "Testing installMysql"

mysqlServerInstalled=$($LIB checkDependencyInstalled mysql-server)
mysqlClientInstalled=$($LIB checkDependencyInstalled mysql-client)

if [ "$mysqlServerInstalled" = "1" ]
then
	$LIB removeDependency mysql-server
fi

if [ "$mysqlClientInstalled" = "1" ]
then
	$LIB removeDependency mysql-client
fi

$LIB installMysql password

mysqlServerInstalled=$($LIB checkDependencyInstalled mysql-server)
mysqlClientInstalled=$($LIB checkDependencyInstalled mysql-client)

if [ "$mysqlServerInstalled" = "1" ]
then
	echo "MySQL Server installed [TEST PASSED]"
else
	echo "MySQL Server not installed [TEST FAILED]"
fi

if [ "$mysqlClientInstalled" = "1" ]
then
	echo "MySQL Client installed [TEST PASSED]"
else
	echo "MySQL Client not installed [TEST FAILED]"
fi


