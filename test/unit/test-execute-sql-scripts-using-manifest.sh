#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/../../lib/lib.sh

echo "Testing executeSqlScriptsUsingManifest"

#create temp folder
workingDir="/tmp/$($LIB getUniqueName exeSqlManifest)"
mkdir $workingDir/sql -p #creating directories
cd $workingDir

rand=$RANDOM

#create SQL files to run
echo "drop table if exists test" >> sql/test1.sql
echo "create table test (id int not null)" >> sql/test2.sql
echo "insert into test (id) values($rand)" >> sql/test3.sql
echo "select * from test;" >> sql/test4.sql

#create sql manifest
echo "sql/test1.sql" >> manifest
echo "sql/test2.sql" >> manifest
echo "sql/test3.sql" >> manifest
echo "sql/test4.sql" >> manifest


result=$($LIB executeSqlScriptsUsingManifest $workingDir test $workingDir/manifest)
result=$result | grep $rand

if [ "$result" = "" ]
then
	echo "[TEST FAILED]"
else
	echo "[TEST PASSED]"
fi

rm -rf $workingDir



