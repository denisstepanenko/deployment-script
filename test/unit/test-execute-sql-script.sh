#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/../../lib/lib.sh

workingDir=$($LIB getUniqueName sqltest)

mkdir $workingDir

#create a test sql script
echo "show tables;" >> $workingDir/test.sql

result=$($LIB executeSqlScript test $workingDir/test.sql | grep test)
if [ "$result" = "" ]
then
	echo "[TEST FAILED]"
else
	echo "[TEST PASSED]"
fi

rm -rf $workingDir

