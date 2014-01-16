#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/../../lib/lib.sh

echo "Testing backupDatabase"

backupDir="/tmp/$($LIB getUniqueName dbBackup)"
mkdir $backupDir 

dbUser="root"
dbPwd="password"
dbName="test"
dbExist=$($LIB checkDatabaseExist $dbName)
if [ "$dbExist" = "0" ]
then
	mysql -u$dbUser -p$dbPwd << !
create database $dbName;
!
fi

$LIB backupDatabase "$dbName" "$backupDir"

if [ -f "$backupDir/test.sql.tar.gz" ]
then
	echo "DB Backed up [TEST PASSED]"
else
	echo "DB didn't backup [TEST FAILED]"
fi

rm -rf $backupDir
