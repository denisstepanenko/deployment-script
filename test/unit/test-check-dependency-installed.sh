#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

installed=$(../../lib/lib.sh checkDependencyInstalled sudo)


if [ $installed -eq 0 ]
then
	echo "sudo not installed, [test failed]"
else
	echo "sudo installed [test passed]"
fi

notInstalledCommand=$(../../lib/lib.sh checkDependencyInstalled asdfasdfasdf)
if [ $notInstalledCommand -eq 0 ]
then
	echo "dummy command not installed [test passed]"
else
	echo "dummy command installed [test failed]"
fi

