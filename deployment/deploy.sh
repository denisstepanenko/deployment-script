#!/bin/bash

ERROR_COUNT=0
MIN_DISK_SPACE=300 #in MB
SAND_BOX_PATH=""
LIVE_SITE_PATH="/var/www/deployment-project"
LIVE_DATABASE_NAME="ror_test2"
LIVE_DOMAIN_NAME="local.deployment.com"
LIVE_SITE_URL="http://$LIVE_DOMAIN_NAME"
#TEST-DATABASE_NAME="test_site"
BACKUP_PATH=""
GET_PROJECT_URL="https://github.com/denisstepanenko/deployment-project.git"

DBUSER="root"
DBPWD="password"

#in most cases this will be the same IP address as the "local.test2.com"
PRODUCTION_SERVER_IP="192.168.0.31"
PRODUCTION_USER="root"
PRODUCTION_PWD=""

SERVER_INSTANCE="test"

#gets directory where the script is executed from, regardless of the working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LIB=$DIR/../lib/lib.sh
sudo chmod 0755 $LIB
sudo chmod 0755 $DIR/content-test.sh

#add hosts entry for local.deployment.com domain
hostAdded=$(sudo less /etc/hosts | grep "$LIVE_DOMAIN_NAME")		
if [ -z "$hostAdded" ]
then
	sudo echo "127.0.0.1 local.deployment.com" >> /etc/hosts 
fi

#set error catch logic
trap incrementErrorCount ERR

prepareEnvironment(){
	#$1 - if --ignore-dependencies parameter was passed in, don't try to install apache, mysql etc.

	if [ "$SERVER_INSTANCE" = "test" ] && [ "$PRODUCTION_PWD" = "" ]
	then
		#production server password only needed when this script is run on test server
		#reads password for root on production. For security reasons this password cannot be stored in the script.
		read -s -p "Enter production server root password: " PRODUCTION_PWD
	fi
	
	echo "Pre-build process started"
	#echo "Checking if enough space available for deployment"

	spaceAvailable=$($LIB getAvailableDiskSpace /tmp)

	if [ $spaceAvailable -lt $MIN_DISK_SPACE ];
	then
		echo "[ERROR]: not enough space to proceed with deployment"		
		incrementErrorCount

		return $ERROR_COUNT
	fi

	#creating sandbox
	sandboxName=$($LIB getUniqueName deployment)
	SAND_BOX_PATH="/tmp/$sandboxName"
	sandboxCreateResult=$((mkdir $SAND_BOX_PATH) | tr -d ' ')

	#check if got any errors during creation of sandbox
	if [ "$sandboxCreateResult" = "" ]
	then
		#echo "Sandbox created successfully!"
		echo "Sandbox path: $SAND_BOX_PATH"
	else
		incrementErrorCount
		return $ERROR_COUNT
		echo "Error occurred while creating sandbox"
	fi
	
	#this will contain the backup of the site which can then be rolled back if needed.
	BACKUP_PATH="$SAND_BOX_PATH/backup"
	mkdir $BACKUP_PATH/site -p
	mkdir $BACKUP_PATH/database -p
	
	currentSiteSize=$($LIB getDirectorySize $LIVE_SITE_PATH)	
	if [ ! "$currentSiteSize" = "0" ]
	then	
		#backup site files and database, this backup will be used for rollbacks if necessary
		cp -r $LIVE_SITE_PATH/* $BACKUP_PATH/site	
	fi
		
	mysqlServerInstalled=$($LIB checkDependencyInstalled mysql)
	if [ $mysqlServerInstalled -gt 0 ]
	then	
		#the following line will error if mysql is not running. This can happen if deployment script was aborted.
		dbExist=$($LIB checkDatabaseExist $LIVE_DATABASE_NAME)		
		if [ $dbExist -gt 0 ]
		then
			$LIB backupDatabase $LIVE_DATABASE_NAME $BACKUP_PATH/database
		fi
	fi
	
	#check if need to install dependencies.
	if [ "$1" = "--ignore-dependencies" ]
	then
		echo "Ignoring dependency installation"
	else
		#check if git is installed, if not install it
		isGitInstalled=$($LIB checkDependencyInstalled git)		
		if [ "$isGitInstalled" = "0" ]
		then
			#git not installed, install it
			$LIB installDependency git
		fi

		#check if apache is installed, if not install it
		isApacheInstalled=$($LIB checkDependencyInstalled apache2)
		if [ "$isApacheInstalled" = "0" ]
		then
			#apache not installed, install it
			$LIB installDependency apache2
		fi

		#check if MySQL is installed, if not install it
		isMysqlInstalled=$($LIB checkDependencyInstalled mysql)
		if [ "$isMysqlInstalled" = "0" ]
		then
			#MySQL not installed, install it
			$LIB installMysql $DBPWD
		fi
		
		#check sshpass is installed. Needed for FTPing file using SFTP, this utility will enter the password for us.
		isSSHpassInstalled=$($LIB checkDependencyInstalled sshpass)
		if [ "$isSSHpassInstalled" = "0" ]
		then			
			$LIB installDependency sshpass
		fi
		
		#install passanger, rails, nodejs and other dependencies for running rails applications
		$LIB installRailsDependencies
	fi

	#stop mysql and apache just in case some configuration will be deployed latter
	#besides we don't want users using the site while something is deploying 
	sudo /etc/init.d/apache2 stop > /dev/null 2>&1
	sudo /etc/init.d/mysql stop > /dev/null 2>&1
		
	echo "*** Pre-Build step completed with $ERROR_COUNT errors. ***"
	echo " "
	
	return $ERROR_COUNT
}

buildProcess(){
	#create build/input directory
	buildInputPath="$SAND_BOX_PATH/build/input"
	buildOutputPath="$SAND_BOX_PATH/build/output"

	buildInputCreateResult=$((mkdir $buildInputPath -p) | tr -d ' ')
	if [ "$buildInputCreateResult" = "" ] 
	then
		echo "$buildInputPath created"
	else
		echo "error creating $buildInputPath"
		incrementErrorCount
		return $ERROR_COUNT
	fi
	#won't be testing if build/output is created as no need for that
	mkdir $buildOutputPath -p

	#download deployment content from git into build/input directory
	git clone $GET_PROJECT_URL $buildInputPath > /dev/null 2>&1

	#check anything was downloaded, if set error and return
	buildInputSize=$($LIB getDirectorySize $buildInputPath)
	if [ "$buildInputSize" = "0" ]
	then
		echo "No content was downloaded from GIT, nothing to deploy!"
		incrementErrorCount
		return $ERROR_COUNT
	fi

	if [ -f $buildInputPath/resources-manifest ]
	then
		#copy files from build/input to build/output
		#but only copy files/dirs that are in the manifest
		echo "Copying files to build/output using manifest"
		$LIB copyToUsingManifest $buildInputPath $buildOutputPath $buildInputPath/resources-manifest
	fi

	#removal-manifest, sql-manifest probably won't be in the resources manifest but it's needed on the next step
	if [ -f $buildInputPath/removal-manifest ]
	then
		cp -rf $buildInputPath/removal-manifest $buildOutputPath	
	fi
	if [ -f $buildInputPath/sql-manifest ]
	then
		cp -rf $buildInputPath/sql-manifest $buildOutputPath	
	fi
	if [ -f $buildInputPath/sql-scripts ]
	then
		cp -rf $buildInputPath/sql-scripts $buildOutputPath	
	fi
	
	#echo "Copy complete"

	if [ -f $buildInputPath/dependency-manifest ]
	then
		#dependency-manifest contains list of configuration files for Apache and MySQL and other
		#dependencies. The DEST dir. is set to root.
		echo "Copying dependency configurations"
		sudo $LIB copyToUsingManifest2 "$buildInputPath/dependency-configurations" $buildInputPath/dependency-manifest
	fi
	
	cd $buildOutputPath	
	#package the build/output to output.tar and leave under build directory
	#tar -zcvf build-output.tar.gz output
	tar -zcf build-output.tar.gz . > /dev/null 2>&1
	
	#create integration directory and copy the package to it
	mkdir $SAND_BOX_PATH/integration -p
	cp -rf build-output.tar.gz $SAND_BOX_PATH/integration 

	#perform cleanup
	rm -rf $SAND_BOX_PATH/build

	#report
	echo "*** Build step completed with $ERROR_COUNT errors. ***"
	echo " "
	
	return $ERROR_COUNT
}

integrationProcess(){
	intInputPath="$SAND_BOX_PATH/integration/input"
	intInputSitePath="$intInputPath/site"
	intInputDbPath="$intInputPath/database"
	intBuildOutputPath="$SAND_BOX_PATH/integration/build-output"
	
	mkdir $intInputSitePath -p
	mkdir $intInputDbPath -p
	mkdir $intBuildOutputPath -p
	
	cd "$intBuildOutputPath"
	#unzip output from prev step into build-output dir
	tar -zxf ../build-output.tar.gz . > /dev/null 2>&1

	currentSiteSize=$($LIB getDirectorySize $LIVE_SITE_PATH)	
	if [ ! "$currentSiteSize" = "0" ]
	then			
		#copy current website to working directory
		cp -r $LIVE_SITE_PATH/* $intInputSitePath
	else
		#if first installation ever, then create the live site path
		mkdir $LIVE_SITE_PATH -p
	fi
		
	#overwrite the current site (working dir) with new (whatever was in the manifest) stuff
	cp -rf $intBuildOutputPath/* $intInputSitePath

	#remove files/dirs that are in removal manifest
	#removal-manifest should NOT contain itself or other manifests or files such as Apache configurations	
	$LIB removeFromUsingManifest $intInputSitePath $intInputSitePath/removal-manifest

	#DB needs to work here, if it doesn't, abort
	sudo /etc/init.d/mysql restart > /dev/null 2>&1
	mysqlRunning=$($LIB checkProcessRunning mysql)
	if [ $mysqlRunning -eq 0 ]
	then
		echo "MySQL didn't restart, aborting..."
		incrementErrorCount
		return $ERROR_COUNT
	fi
	
	#check if DB exist, if not it must be the first time the script is run, therefore create DB
	dbExist=$($LIB checkDatabaseExist $LIVE_DATABASE_NAME)
	if [ $dbExist -eq 0 ]
	then
		mysql -u$DBUSER -p$DBPWD << !
create database $LIVE_DATABASE_NAME;
!
	fi
	
	echo "Executing scripts using manifest..."
	#run DB scripts against DB 
	$LIB executeSqlScriptsUsingManifest $intInputSitePath/sql-scripts $LIVE_DATABASE_NAME $intInputSitePath/sql-manifest
	
	#remove everything from the current live location
	rm -rf $LIVE_SITE_PATH/*
	#copy integrated file system to live
	cp -rf $intInputSitePath/* $LIVE_SITE_PATH
	
	#set permissions so rails can run properly
	sudo chmod -R 0777 $LIVE_SITE_PATH
	
	#if deployment is running for the first time, run rake db:migrate to create the database
	if [ "$currentSiteSize" = "0" ]
	then
		cd $LIVE_SITE_PATH
		sudo bundle install
		#the bundle exec is needed because bundler gem version isntalled automatically is newer than the site
		sudo bundle exec rake db:migrate
	fi
	
	#restarting because if apache or mysql didn't stop for some odd reason, they will be restarted anyway.
	sudo /etc/init.d/apache2 restart > /dev/null 2>&1	
	
	#cleanup
	rm -rf $SAND_BOX_PATH/integration
	
	#report
	echo "*** Integration step completed with $ERROR_COUNT errors. ***"
	echo " "
	
	return $ERROR_COUNT
}

testProcess(){
	#here the tests will be run against the current DB and website. If some scripts should be excluded from being run on live instance, then wrap those tests in an "if" block checking the current instance.
	
	testPath="$SAND_BOX_PATH/test"
	
	cd $DIR
	testResult=$(sudo bash ./content-test.sh $SAND_BOX_PATH $LIVE_SITE_URL $LIVE_SITE_PATH | grep "ERROR COUNT: 0" | wc -l)
		
	if [ "$testResult" = "0" ]
	then
		#if the line "ERROR COUNT: 0" is not found, means test didn't run successfully
		incrementErrorCount					
	fi
		
	# #if no errors copy to next step
	# if [ "$ERROR_COUNT" = "0" ]
	# then
		# cd $testPath
		# mkdir $SAND_BOX_PATH/deployment
		# cp -rf integration-output.tar.gz $SAND_BOX_PATH/deployment
	# fi
	
	#cleanup
	rm -rf $testPath
		
	echo "*** Tests completed with $ERROR_COUNT errors. ***"
	echo " "
	
	return $ERROR_COUNT
}

deploymentProcess(){			
	#$1 - "--ignore-dependencies-remote"
	
	#cd $SAND_BOX_PATH/deployment
	remoteSandbox=$SAND_BOX_PATH
	
	#check if executing remotely or on live. 
	#If executed on test the script will have to be uploaded to live, then it will have to be started with the following command: "bash deploy.sh start deployment live"
	if [ "$SERVER_INSTANCE" = "test" ]
	then
		#change to DEPLOYMENT directory
		cd $DIR/../
		
		if [ -f deployment-script.tar.gz ]
		then
			#remove the zip from previous install
			rm -rf deployment-script.tar.gz
		fi

		#package the deployment scripts
		tar -zcf deployment-script.tar.gz . > /dev/null 2>&1
		
		remoteScriptDir="$remoteSandbox/DEPLOYMENT"
		
		#create sandbox remotely
		sshpass -p$PRODUCTION_PWD ssh -oStrictHostKeyChecking=no $PRODUCTION_USER@$PRODUCTION_SERVER_IP mkdir $remoteScriptDir -p
				
		#upload deployment script
		sshpass -p$PRODUCTION_PWD sftp -oBatchMode=no -b - $PRODUCTION_USER@$PRODUCTION_SERVER_IP << !
#changing directory remotely
cd $remoteScriptDir
#put integration-output.tar.gz
put deployment-script.tar.gz
exit
!
		
		mkdir $SAND_BOX_PATH/deployment -p
		
		ignoreDependencies=""
		if [ "$1" = "--ignore-dependencies-remote" ]
		then
			ignoreDependencies="--ignore-dependencies"
		fi
				
		#writing a script to be executed remotely
		echo " #!/bin/bash
		
		cd $remoteScriptDir
		sudo tar -zxf deployment-script.tar.gz . > /dev/null 2>&1
		sudo bash $remoteSandbox/DEPLOYMENT/deployment/deploy.sh start deployment live $PRODUCTION_PWD $ignoreDependencies > $remoteSandbox/deployment.log
		#sudo bash $remoteSandbox/DEPLOYMENT/deployment/deploy.sh start deployment live $PRODUCTION_PWD --ignore-dependencies > $remoteSandbox/deployment.log
		cat $remoteSandbox/deployment.log " > $SAND_BOX_PATH/deployment/remote.sh

		echo ""
		echo "Remote Deployment Started..."
		remoteLog=$(sshpass -p$PRODUCTION_PWD ssh $PRODUCTION_USER@$PRODUCTION_SERVER_IP 'bash -s' < $SAND_BOX_PATH/deployment/remote.sh)
				
		remotePreBuildErrors=$(echo "$remoteLog" | grep "\*\*\* Pre-Build step completed with [0-9]\+ errors. \*\*\*" | grep -oP "[0-9]+")
		remoteBuildErrors=$(echo "$remoteLog" | grep "\*\*\* Build step completed with [0-9]\+ errors. \*\*\*" | grep -oP "[0-9]+")
		remoteIntegrationErrors=$(echo "$remoteLog" | grep "\*\*\* Integration step completed with [0-9]\+ errors. \*\*\*" | grep -oP "[0-9]+")
		remoteTestErrors=$(echo "$remoteLog" | grep "\*\*\* Tests completed with [0-9]\+ errors. \*\*\*" | grep -oP "[0-9]+")

		echo ""
		echo "REMOTE DEPLOYMENT RESULTS"
		echo "Pre-Build: $remotePreBuildErrors errors."
		echo "Build: $remoteBuildErrors errors."
		echo "Integration: $remoteIntegrationErrors errors."
		echo "Test: $remoteTestErrors errors."
		
		if [ "$remotePreBuildErrors" = "0" ] && [ "$remoteBuildErrors" = "0" ] && [ "$remoteIntegrationErrors" = "0" ] && [ "$remoteTestErrors" = "0" ]
		then
			echo "Deployment Completed Successfully"
		else
			echo "Deployment Failed."
		fi

	else
		#if running from live instance, then show the message
		echo "*** Deployment completed with $ERROR_COUNT errors. ***"
	fi
}


incrementErrorCount(){
	ERROR_COUNT=$((ERROR_COUNT+1))
	return $ERROR_COUNT
}
decrementErrorCount(){
	ERROR_COUNT=$((ERROR_COUNT-1))
	return $ERROR_COUNT
}

start(){
	#$1 - is the individual step to run, can be one of the following values (without quotes): "build", "integration", "test", "deployment"
	#$2 - this param indicates whether the script is executing locally or remotely	
	#$3 - production password
	#$4 - "--ignore-dependencies", if used then dependencies won't be installed
	#$5 - "--ignore-dependencies-remote", if used the dependencies won't be installed remotelly
	
	clear 
	
	if [ "$2" = "live" ]
	then
		SERVER_INSTANCE="live"
	else
		SERVER_INSTANCE="test"
	fi
	
	PRODUCTION_PWD=$3

	#this function starts the deployment
	prepareEnvironment $4
	# if [ $ERROR_COUNT -gt 0 ]
	# then
		# echo "Pre-Build aborted due to errors"
	# else
		# echo "Pre-Build completed successfully"
	# fi
	
	#check if execute deployment
	if [ "$1" = "build" ] || [ "$1" = "integration" ] || [ "$1" = "test" ] || [ "$1" = "deployment" ] 
	then
		#a particular step requested, this step will always have to be executed
		buildProcess
		if [ $ERROR_COUNT -gt 0 ]
		then
			echo "Build aborted due to errors"
			return 1			
		fi
	fi
	
	#check if execute integration
	if [ "$1" = "integration" ] || [ "$1" = "test" ] || [ "$1" = "deployment" ] 
	then
		#if the integration step (or the one after it) is requested, then execute this step
		integrationProcess
		if [ $ERROR_COUNT -gt 0 ]
		then
			echo "Integration aborted due to errors"
			rollback	
			return 1			
		fi
	fi
	
	#check if execute test
	if [ "$1" = "test" ] || [ "$1" = "deployment" ] 
	then
		#if the test step (or the one after it) is requested, then execute this step
		testProcess
		if [ $ERROR_COUNT -gt 0 ]
		then
			echo " "			
			rollback	
			return 1				
		fi
	fi
	
	#check if execute live deployment process	
	if [ "$1" = "deployment" ] 
	then
		#if the deployment step is requested, then execute this step
		deploymentProcess $5
		if [ $ERROR_COUNT -gt 0 ]
		then
			echo " "					
			rollback	
			return 1								
		fi
	fi	
}

rollback(){
		
	sudo /etc/init.d/apache2 stop > /dev/null 2>&1
	
	echo "Rolling back site file system..."
	
	#remove everything from the current live location
	rm -rf $LIVE_SITE_PATH/*
	cp -rf $BACKUP_PATH/site/* $LIVE_SITE_PATH
	
	echo "Rolling back site database..."
	$LIB restoreDatabase $LIVE_DATABASE_NAME $BACKUP_PATH/database/*.tar.gz
	
	sudo /etc/init.d/apache2 restart > /dev/null 2>&1
	sudo /etc/init.d/mysql restart > /dev/null 2>&1
}


#the following is used to execute functions from this script outside of this script
$@
