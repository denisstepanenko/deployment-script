#!/bin/bash

errorCount=0

testFn(){
	echo
	echo error occoured!
	echo

	errorCount=$(($errorCount+1))
}


trap testFn ERR  

asdfasdf

asdfasd


asdfasdf


asdfasd

echo $errorCount
