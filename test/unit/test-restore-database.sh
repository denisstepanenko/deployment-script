#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/../../lib/lib.sh

backupDir="/tmp/$($LIB getUniqueName db-backup-restore)"
mkdir $backupDir -p

rand=$RANDOM

#in case something went wrong in previous tests, remove the test DB
mysql -uroot -ppassword -e "drop table if exists backupTest" "test"

echo "Before Backup:"
echo

#drop and re-create a test table and insert a record into it
mysql -uroot -ppassword -e "drop table if exists test" "test"
mysql -uroot -ppassword -e "create table test (id int not null); insert into test (id) values ($rand);" "test"

mysql -uroot -ppassword -e "show tables;" test
echo 
mysql -uroot -ppassword -e "select * from test" "test"

$LIB backupDatabase "test" "$backupDir"

echo
echo "backup dir contains: $(ls $backupDir)"


mysql -uroot -ppassword -e "create table backupTest(id int not null)" "test"

echo
echo "Before backup restore:"
mysql -uroot -ppassword -e "show tables;" test


backupFile=$((ls $backupDir/*) | tr -d ' ')
echo "backup file: $backupFile"

$LIB restoreDatabase "test" "$backupFile"

echo
echo "After restore:"
mysql -uroot -ppassword -e "show tables;" "test"

selectionResults=$(echo $(mysql -uroot -ppassword -e "select * from test" test) | grep $rand)
if [ "$selectionResults" = "" ]
then
	echo "$selectionResults: [TEST FAILED]"
else
	echo "$selectionResults: [TEST PASSED]"
fi

rm -rf $backupDir
