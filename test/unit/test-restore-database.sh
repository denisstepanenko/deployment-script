#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/../../lib/lib.sh

echo "Testing restoreDatabase"

backupDir="/tmp/$($LIB getUniqueName db-backup-restore)"
mkdir $backupDir -p

rand=$RANDOM

dbTestTable="test"
dbBackupTable="backupTest"
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

#in case something went wrong in previous tests, remove the test table
mysql -u$dbUser -p$dbPwd -e "drop table if exists $dbBackupTable" "$dbName"

#drop and re-create a test table and insert a record into it
mysql -u$dbUser -p$dbPwd -e "drop table if exists $dbTestTable" "$dbName"
mysql -u$dbUser -p$dbPwd -e "create table $dbTestTable (id int not null); insert into $dbTestTable (id) values ($rand);" "$dbName"

#mysql -u$dbUser -p$dbPwd -e "show tables;" $dbName
#mysql -u$dbUser -p$dbPwd -e "select * from $dbTestTable" "$dbName"

$LIB backupDatabase "$dbName" "$backupDir"

#echo "backup dir contains: $(ls $backupDir)"


mysql -u$dbUser -p$dbPwd -e "create table $dbBackupTable(id int not null)" "$dbName"

#echo "Before backup restore:"
#mysql -u$dbUser -p$dbPwd -e "show tables;" $dbName


backupFile=$((ls $backupDir/*) | tr -d ' ')
#echo "backup file: $backupFile"

$LIB restoreDatabase "$dbName" "$backupFile"

#echo "After restore:"
#mysql -u$dbUser -p$dbPwd -e "show tables;" "$dbName"

selectionResults=$(echo $(mysql -u$dbUser -p$dbPwd -e "select * from $dbTestTable" $dbName) | grep $rand)
if [ "$selectionResults" = "" ]
then
	echo "Record $rand lost: $selectionResults: [TEST FAILED]"
else
	echo "Record $rand restored: $selectionResults: [TEST PASSED]"
fi

removedTable=$(mysql -u$dbUser -p$dbPwd -e "show tables;" $dbName | grep $dbBackupTable | wc -l)
if [ "$removedTable" = "0" ]
then
	echo "Table '$dbBackupTable' removed by restore. [TEST PASSED]"
else
	echo "Table '$dbBackupTable' not removed by restore. [TEST FAILED]"
fi

rm -rf $backupDir
