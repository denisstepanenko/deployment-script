#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "testing removal and re-installation of git"

gitInstalled=$($DIR/../../lib/lib.sh checkDependencyInstalled git)

if [ "$gitInstalled" = "0" ]
then
	echo "git not installed"


	echo "installing git"
	$DIR/../../lib/lib.sh installDependency git

	gitInstalled=$($DIR/../../lib/lib.sh checkDependencyInstalled git)
        if [ "$gitInstalled" = "0" ]
        then
                echo "Git not installed [test failed]"
        else
                echo "Git installed [test passed]"
        fi


else
	echo "removing git"
	$DIR/../../lib/lib.sh removeDependency git

	gitInstalled=$($DIR/../../lib/lib.sh checkDependencyInstalled git)
	if [ "$gitInstalled" = "0" ]
	then
		echo "Git removed [test passed]"
	else
		echo "Git not removed [test failed]"
	fi
fi




