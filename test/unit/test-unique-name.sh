#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/../../lib/lib.sh

echo "Testing getUniqueName"

uniqueName=$($LIB getUniqueName deployment)
uniqueName2=$($LIB getUniqueName deployment2)

if [ "$uniqueName" = "" ]
then
	echo "Unique name is empty. [TEST FAILED]"
else
	echo "Unique name: '$uniqueName'. [TEST PASSED]"
fi

if [ "$uniqueName" = "$uniqueName2" ]
then
	echo "Names generated are the same. [TEST FAILED]"
else
	echo "Names generated are different. [TEST PASSED]"
fi
