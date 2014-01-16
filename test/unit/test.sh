#!/bin/bash

#gets directory where the script is executed from, regardless of the working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LIB=$DIR/../../lib/lib.sh

errorCount=0

errTrapFn(){
	echo
	echo "Error occoured during test."
	echo
	exit

	errorCount=$(($errorCount+1))
}

trap errTrapFn ERR  

sudo bash $DIR/test-check-dependency-installed.sh
sudo bash $DIR/test-install-remove-dependency.sh

sudo bash $DIR/test-check-process-running.sh
sudo bash $DIR/test-disk-space.sh
sudo bash $DIR/test-get-directory-size.sh
sudo bash $DIR/test-unique-name.sh



sudo bash $DIR/test-install-mysql.sh
sudo bash $DIR/test-backup-database.sh
sudo bash $DIR/test-restore-database.sh
sudo bash $DIR/test-execute-sql-script.sh
sudo bash $DIR/test-execute-sql-scripts-using-manifest.sh

commented out as it takes about 15 minutes to run
sudo bash $DIR/test-install-rails-dependencies.sh

#TODO: fix test $DIR/test-copy-to-using-manifest.sh
#sudo bash $DIR/test-copy-to-using-manifest.sh
sudo bash $DIR/test-remove-from-using-manifest.sh

echo $errorCount





