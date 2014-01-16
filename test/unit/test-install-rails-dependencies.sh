#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/../../lib/lib.sh

echo "Testing installRailsDependencies"

$LIB installRailsDependencies

depInstalled=$(checkDependencyInstalled apt-transport-https)
if [ "$depInstalled" = "0" ]
then
	echo "apt-transport-https is not installed [TEST FAILED]"
	exit
else
	echo "apt-transport-https installed [TEST PASSED]"
fi

depInstalled=$(checkDependencyInstalled libapache2-mod-passenger)
if [ "$depInstalled" = "0" ]
then
	echo "libapache2-mod-passenger is not installed [TEST FAILED]"
	exit
else
	echo "libapache2-mod-passenger installed [TEST PASSED]"
fi

depInstalled=$(checkDependencyInstalled libcurl4-openssl-dev)
if [ "$depInstalled" = "0" ]
then
	echo "libcurl4-openssl-dev is not installed [TEST FAILED]"
	exit
else
	echo "libcurl4-openssl-dev installed [TEST PASSED]"
fi

depInstalled=$(checkDependencyInstalled ruby1.9.1-dev)
if [ "$depInstalled" = "0" ]
then
	echo "ruby1.9.1-dev is not installed [TEST FAILED]"
	exit
else
	echo "ruby1.9.1-dev installed [TEST PASSED]"
fi

depInstalled=$(checkDependencyInstalled apache2-threaded-dev)
if [ "$depInstalled" = "0" ]
then
	echo "apache2-threaded-dev is not installed [TEST FAILED]"
	exit
else
	echo "apache2-threaded-dev installed [TEST PASSED]"
fi

depInstalled=$(checkDependencyInstalled libapr1-dev)
if [ "$depInstalled" = "0" ]
then
	echo "libapr1-dev is not installed [TEST FAILED]"
	exit
else
	echo "libapr1-dev installed [TEST PASSED]"
fi

depInstalled=$(checkDependencyInstalled nodejs)
if [ "$depInstalled" = "0" ]
then
	echo "nodejs is not installed [TEST FAILED]"
	exit
else
	echo "nodejs installed [TEST PASSED]"
fi

