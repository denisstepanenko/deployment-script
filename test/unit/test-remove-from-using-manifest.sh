#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

inputDir="/tmp/manifest-test/input"
#outputDir="/tmp/manifest-test/output"


#first run the copy test which would create the folders a data to be removed
bash ./test-copy-to-using-manifest.sh


#create remove manifest
echo "file1.txt" >> "$inputDir/manifest-rm"
echo "sub1" >> "$inputDir/manifest-rm"

$DIR/../../lib/lib.sh removeFromUsingManifest $inputDir $inputDir/manifest-rm

#ASSERTS
if [ -f $inputDir/file1.txt ]
then
	echo "$inputDir/file1.txt not removed [TEST FAILED]"
else
	echo "$inputDir/file1.txt removed [TEST PASSED]"
fi


if [ -d $inputDir/sub1 ]
then
        echo "$inputDir/sub1 not removed [TEST FAILED]"
else
        echo "$inputDir/sub1 removed [TEST PASSED]"
fi

