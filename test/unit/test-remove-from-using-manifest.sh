#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIB=$DIR/../../lib/lib.sh

echo "Testing removeFromUsingManifest"

baseDir="$($LIB getUniqueName manifest-test)"
inputDir="/tmp/$baseDir/input"
#outputDir="/tmp/manifest-test/output"

#first remove test dirs that could be left from last test
#as this test doesn't remove the test dir because a tester might want to check content
rm -rf -- $inputDir
rm -rf -- $outputDir

mkdir $inputDir -p
mkdir $outputDir -p

#writing manifest
echo "file1.txt" >> $inputDir/manifest
echo "file2.txt" >> $inputDir/manifest

#sub directories are relative to the input directory
echo "sub1/file3.txt" >> $inputDir/manifest
echo "sub1/sub2/file4.txt" >> $inputDir/manifest

#create test input files/dirs and its content
echo "file1.txt content" >> $inputDir/file1.txt
echo "file2.txt content" >> $inputDir/file2.txt

mkdir $inputDir/sub1/sub2 -p
echo "sub1/file3.txt" >> $inputDir/sub1/file3.txt
echo "sub1/sub2/file4.txt" >> $inputDir/sub1/sub2/file4.txt

#now create files that are not in the manifest, these shouldn't be copied into output dir
mkdir $inputDir/sub1/sub3 -p
mkdir $inputDir/sub2 
echo "file5.txt content" >> $inputDir/sub1/sub3/file5.txt
echo "file6.txt content" >> $inputDir/sub2/file6.txt

#create remove manifest
echo "file1.txt" >> "$inputDir/manifest-rm"
echo "sub1" >> "$inputDir/manifest-rm"

$LIB removeFromUsingManifest $inputDir $inputDir/manifest-rm

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

rm -rf $baseDir