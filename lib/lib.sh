#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/lib.sh


getAvailableDiskSpace(){
	#$1 is the folder of which the free space should be got from
	echo $(df $1 -m -P | grep /dev | cut -b 36-46 | tr -d ' ')
}

getUniqueName(){
	#$1 is the first part of the unique name
	#the second part of the unique name will be timestamp

	timestamp=$(date +"%Y%m%d%H%M")
	echo "$1-$timestamp"
}

checkDependencyInstalled(){
	#$1 is the command name to be checked if installed
	#dependencyPath=$((which $1) | tr -d ' ')
	dependencyPath=$((dpkg --get-selections | grep $1) | tr -d ' ')
	if [ "$dependencyPath" = "" ]
	then
		echo 0
	else
		echo 1
	fi
}

installDependency(){
	echo "Installing '$1'..."
	#$1 - name of the dependency, i.e. apache2
	sudo apt-get update > /dev/null 2>&1
	#installs dependencies that don't need any interaction with the user
	#i.e. dependencies that can be installed silently
	sudo apt-get -q -y install $1 > /dev/null 2>&1
}

removeDependency(){
	echo "Removing '$1'..."
	#removed dependencies
	sudo apt-get -q -y remove $1 > /dev/null 2>&1
}

installMysql(){
	#$1 is the root password for MySql
	echo ""
	echo "Installing 'MySQL'..."
	
	sudo apt-get update > /dev/null 2>&1

	password="$1"
	sudo apt-get -q -y remove mysql-server mysql-client > /dev/null 2>&1
	sudo echo mysql-server mysql-server/root_password password $password | debconf-set-selections
	sudo echo mysql-server mysql-server/root_password_again password $password | debconf-set-selections
	sudo apt-get -q -y install mysql-server mysql-client > /dev/null 2>&1
	
	echo ""
	echo ""
}

getDirectorySize(){
	#$1 - directory name
	
	#the "K" is the delimiter so only string before K (stands for KB) will be taken
	if [ -d "$1" ]
	then
		dirSize=$(du -sh $1 | cut -d"K" -f1)
		echo $dirSize
	else
		#default to 0KB in case dir. doesn't exist
		echo 0
	fi
}

copyToUsingManifest(){
#$1 - is the source directory
#$2 - is the destination directory
#$3 - is the manifest file path which lists files to copy line by line

	cd $1 #need to change dir here so the cp --parent param works properly
	
	#14-01-14: removed --parents 
	#cat $3 | xargs -I % cp -rf --parents % $2
	cat $3 | xargs -I % cp -rf % $2
}

copyToUsingManifest2(){
#this version of function copies files using manifest however using a relative directory
#$1 - is the source directory
#$2 - is the manifest file path which lists files to copy line by line

	cat $2 | xargs -I % cp -rf $1% %
}

removeFromUsingManifest(){
#$1 - is the base directory where the files should be removed from
#$2 - is the manifest path

	cd $1
	cat $2 | xargs -I % rm -rf %
}

executeSqlScriptsUsingManifest(){
#$1 - is the script source directory
#$2 - is the target DB name
#$3 - is the manifest file path

	cd $1
	cat $3 | xargs -I % $LIB executeSqlScript $2  %
}

checkProcessRunning(){
	#$1 is the name of the process to check
	isRunning=$(ps -ef | grep $1 | grep -v grep | wc -l)
	echo $isRunning
}

executeSqlScript(){
#$1 - database name
#$2 - script path
        user="root"
        password="password"

	mysql -u$user -p$password $1 < $2
}


backupDatabase(){
#$1 - database name
#$2 - target directory path
	user="root"
	password="password"

	databases=`mysql -u$user -p$password -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema)"`
 
	cd $2

	for db in $databases; do
	if [ "$db" = "$1" ]
	then
		mysqldump --force --opt --user=$user -p$password --databases $db > "$db.sql"
		tar -zcf "$db.sql.tar.gz" "$db.sql"
		rm -rf "$db.sql"
	fi
	done

}

restoreDatabase(){
#$1 - database name
#$2 - source tar file path
	user="root"
	password="password"

	workingDir="/tmp/$($LIB getUniqueName dbRestore)"
	mkdir $workingDir -p

	cd $workingDir

	tar -xzf "$2"

	#first drop the DB this is to remove tables that are not  in the 
	#sql script
	mysql -u$user -p$password -e "drop database $1"

	#recreate the DB, however this is not really needed as script would do
	#that anyway
	mysql -u$user -p$password -e "create database $1"

	restoreFile=$(ls $workingDir)

	mysql -u$user -p$password $1 < $restoreFile

	rm -rf $workingDir
}

checkDatabaseExist(){
#$1 - database name
	result=$(mysql -uroot -ppassword -e "show databases;" | grep $1 | wc -l)
	echo $result
	#TODO write unit test
}

installRailsDependencies(){
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7	> /dev/null 2>&1
	$LIB installDependency apt-transport-https
	
	depInstalled=$(checkDependencyInstalled apt-transport-https)
	if [ "$depInstalled" = "0" ]
	then
		echo "apt-transport-https is not installed, aborting..."
		return 
	fi
	
	repository="deb https://oss-binaries.phusionpassenger.com/apt/passenger precise main"
	repositoryFileName="/etc/apt/sources.list.d/passenger.list"
	
	repositoryAdded=$(sudo less /etc/apt/sources.list.d/passenger.list | grep "$repository")		
	#check if empty string
	if [ ! -f $repositoryFileName ] || [ -z "$repositoryAdded" ]
	then
		#update repository sources 
		sudo echo "# Ubuntu 12.04" >> $repositoryFileName 
		sudo echo $repository >> $repositoryFileName		
	fi
	
	sudo chown root: $repositoryFileName
	sudo chmod 600 $repositoryFileName

	$LIB installDependency libapache2-mod-passenger
	depInstalled=$(checkDependencyInstalled libapache2-mod-passenger)
	if [ "$depInstalled" = "0" ]
	then
		echo "libapache2-mod-passenger is not installed, aborting..."
		return 
	fi
	
	#the following switch to root is required because otherwise can't compile passenger properly and also wouldn't be able to configure it properly
	#sudo -s
	
	sudo gem install -v=4.0.35 passenger
	
	$LIB installDependency libcurl4-openssl-dev
	depInstalled=$(checkDependencyInstalled libcurl4-openssl-dev)
	if [ "$depInstalled" = "0" ]
	then
		echo "libcurl4-openssl-dev is not installed, aborting..."
		return 
	fi
	
	$LIB installDependency ruby1.9.1-dev
	depInstalled=$(checkDependencyInstalled ruby1.9.1-dev)
	if [ "$depInstalled" = "0" ]
	then
		echo "ruby1.9.1-dev is not installed, aborting..."
		return 
	fi
	
	$LIB installDependency apache2-threaded-dev
	depInstalled=$(checkDependencyInstalled apache2-threaded-dev)
	if [ "$depInstalled" = "0" ]
	then
		echo "apache2-threaded-dev is not installed, aborting..."
		return 
	fi
	
	$LIB installDependency libapr1-dev
	depInstalled=$(checkDependencyInstalled libapr1-dev)
	if [ "$depInstalled" = "0" ]
	then
		echo "libapr1-dev is not installed, aborting..."
		return 
	fi
	
	#-a for "auto", silent compilation
	sudo passenger-install-apache2-module -a > /dev/null 2>&1
	
	#add some configurations for the above module (overwriting the current config)
	sudo sh -c "echo 'LoadModule passenger_module /var/lib/gems/1.9.1/gems/passenger-4.0.35/buildout/apache2/mod_passenger.so' > /etc/apache2/mods-available/passenger.load"
	
	sudo sh -c "echo 'PassengerRoot /var/lib/gems/1.9.1/gems/passenger-4.0.35' > /etc/apache2/mods-available/passenger.conf"
	sudo sh -c "echo 'PassengerDefaultRuby /usr/bin/ruby1.9.1' >> /etc/apache2/mods-available/passenger.conf" #append this line
	
	#enable passanger
	sudo a2enmod passenger
	
	echo "Installing Rails gem..."
	sudo gem install rails
	
	installDependency nodejs
	depInstalled=$(checkDependencyInstalled nodejs)
	if [ "$depInstalled" = "0" ]
	then
		echo "nodejs is not installed, aborting..."
		return 
	fi
	
	#THIS HAS TO BE DONE BY DEPLOYMENT SCRIPT
	##set permissions recursively to some of the folders so apache can run the code
	#chmod -R 0777 /var/www/test2/
	
	
}


#the below arg is used to call functions of this library 
$@
