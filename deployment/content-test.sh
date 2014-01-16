#!/bin/bash


# DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# LIB=$DIR/../lib/lib.sh

SAND_BOX_PATH=$1
LIVE_SITE_URL=$2
LIVE_SITE_PATH=$3
ERROR_COUNT=0

incrementErrorCount(){
	ERROR_COUNT=$((ERROR_COUNT+1))
	return $ERROR_COUNT
}

testPath="$SAND_BOX_PATH/test"
tempPath="$testPath/temp"
	
mkdir $tempPath -p
	
#test the site is running
cd $tempPath
#trying to download index.html page. If apache serves this page, then it must be working OK. Otherwise if a 500 or a 404 is returned, means that either this page was
#removed of something is wrong with apache. Ideally there should be some other page for testing this, i.e. test.html.
wget -q $LIVE_SITE_URL
if [ ! -f "index.html" ]
then
	#file not found, must be due to some error. 
	incrementErrorCount		
	#return $ERROR_COUNT
else
	echo "Test content sucessfully downloaded from: $LIVE_SITE_URL"
fi

cd $LIVE_SITE_PATH 
#populate the test DB with data from current live DB
sudo bundle exec rake db:test:clone
#redirecting the strerr to black hole
testResult=$(sudo bundle exec rake test 2> /dev/null | grep "0 errors" | wc -l)

if [ "$testResult" = "0" ]
then
	#if the line "0 errors" not found, means test didn't run successfully
	incrementErrorCount					
fi
	
echo "ERROR COUNT: $ERROR_COUNT"


