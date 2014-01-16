#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/../../lib/lib.sh

echo "Testing getAvailableDiskSpace"

#get available space on the 
availableSpace=$($LIB getAvailableDiskSpace /etc)

if [ $availableSpace -gt 0 ];
then
	echo "Available space is non-zero. [TEST PASSED]"
else
	echo "Available space of /etc is <=0.[TEST FAILED]"
fi

availableSpace=$($LIB getAvailableDiskSpace /etcasdfas)
if [ $availableSpace -gt 0 ];
then
	echo "Available space of directory that doesn't exist is >0.[TEST FAILED]"
else
	echo "Available space of directory that doesn't exit is <=0. [TEST PASSED]"
fi