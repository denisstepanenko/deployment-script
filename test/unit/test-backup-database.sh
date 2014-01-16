#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LIB=$DIR/../../lib/lib.sh

backupDir="/tmp/$($LIB getUniqueName dbBackup)"
mkdir $backupDir 

$LIB backupDatabase "test" "$backupDir"

if [ -f "$backupDir/test.sql.tar.gz" ]
then
	echo "DB Backed up [TEST PASSED]"
else
	echo "DB Not Backedup [TEST FAILED]"
fi

rm -rf $backupDir
