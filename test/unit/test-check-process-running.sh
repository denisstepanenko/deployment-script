#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

processName="getty"
numberOfProcesses=$($DIR/../../lib/lib.sh checkProcessRunning $processName)

if [ $numberOfProcesses -gt 0 ]
then
	echo "Process $processName running [TEST PASSED]"
else
	echo "Process $processName is not running [TEST FAILED]"
fi


processName="askljdfhlakjsdhflaj"
numberOfProcesses=$($DIR/../../lib/lib.sh checkProcessRunning $processName)

if [ $numberOfProcesses -gt 0 ]
then
        echo "Process $processName running [TEST FAILED]"
else
        echo "Process $processName is not running [TEST PASSED]"
fi

