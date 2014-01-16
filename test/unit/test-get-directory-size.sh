#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/../../lib/lib.sh

echo "Testing getDirectorySize"

dirToCheck="/etc/ssh"
dirSize=$($LIB getDirectorySize $dirToCheck)

if [ $dirSize -gt 0 ]
then
	echo "$dirToCheck is $dirSize KB [TEST PASSED]"
else
	if [ -d "$dirToCheck" ]
	then
		#directory will always be at leas 4.0 KB
		 echo "$dirToCheck is $dirSize KB [TEST FAILED]"
	else
		#this test passed as lib checks and returns 0 if dir not found
		echo "$dirToCheck doesn't exist [TEST PASSED]"
	fi
fi

dirToCheck="/asdfasd/afsdasd/asdfs"
dirSize=$($LIB getDirectorySize $dirToCheck)

if [ $dirSize -eq 0 ]
then
	echo "$dirToCheck is 0KB [TEST PASSED]"
else
	echo "$dirToCheck is $dirSize [TEST FAILED]"
fi


