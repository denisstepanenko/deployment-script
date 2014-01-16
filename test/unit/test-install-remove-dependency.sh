#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/../../lib/lib.sh

echo "Testing installDependency and removeDependency"

gitInstalled=$($LIB checkDependencyInstalled git)

testGitInstall(){
	$LIB installDependency git

	gitInstalled=$($LIB checkDependencyInstalled git)
	if [ "$gitInstalled" = "0" ]
	then
			echo "Git not installed [TEST FAILED]"
	else
			echo "Git installed [TEST PASSED]"
	fi
}

testGitRemoval(){
	$LIB removeDependency git

	gitInstalled=$($LIB checkDependencyInstalled git)
	if [ "$gitInstalled" = "0" ]
	then
		echo "Git removed [TEST PASSED]"
	else
		echo "Git not removed [TEST FAILED]"
	fi
}

if [ "$gitInstalled" = "0" ]
then
	testGitInstall
	testGitRemoval
else
	testGitRemoval	
	testGitInstall	
fi




