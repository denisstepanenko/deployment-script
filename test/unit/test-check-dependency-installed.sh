#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/../../lib/lib.sh

echo "Testing checkDependencyInstalled"

installed=$($LIB checkDependencyInstalled sudo)


if [ $installed -eq 0 ]
then
	echo "sudo not installed, [TEST FAILED]"
else
	echo "sudo installed [TEST PASSED]"
fi

notInstalledCommand=$($LIB checkDependencyInstalled asdfasdfasdf)
if [ $notInstalledCommand -eq 0 ]
then
	echo "Dummy command not installed [TEST PASSED]"
else
	echo "Dummy command installed [TEST FAILED]"
fi

