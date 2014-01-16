
#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#PREPARE TEST ENVIRONMENT
#first create test directories
inputDir="/tmp/manifest-test/input"
outputDir="/tmp/manifest-test/output"

#first remove test dirs that could be left from last test
#as this test doesn't remove the test dir because a tester might want to check content
rm -rf -- $inputDir
rm -rf -- $outputDir

mkdir $inputDir -p
mkdir $outputDir -p

echo "$inputDir"
echo "$outputDir"

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

$DIR/../../lib/lib.sh copyToUsingManifest $inputDir $outputDir $inputDir/manifest

#ASSERTS for files that shouldn't have been copied
if [ -d $outputDir/sub2 ]
then
	echo "$outputDir/sub2 dir was copied [TEST FAILED]"
else
	echo "$outputDir/sub2 was not copied [TEST PASSED]"
fi

if [ -d $outputDir/sub1/sub3 ]
then
        echo "$outputDir/sub1/sub3 dir was copied [TEST FAILED]"
else
        echo "$outputDir/sub1/sub3 was not copied [TEST PASSED]"
fi
if [ -f $outputDir/sub1/sub3/file5.txt ]
then
        echo "$outputDir/sub1/sub3/file5.txt was copied [TEST FAILED]"
else
        echo "$outputDir/sub1/sub3/file5.txt was not copied [TEST PASSED]"
fi
if [ -f $outputDir/sub2/file6.txt ]
then
        echo "$outputDir/sub2/file6.txt was copied [TEST FAILED]"
else
        echo "$outputDir/sub2/file6.txt was not copied [TEST PASSED]"
fi

#ASSERS FOR FILES/DIRS THAT SHOULD HAVE BEEN COPIED

if [ -f $outputDir/file1.txt ]
then
        echo "$outputDir/file1.txt was copied [TEST PASSED]"
else
        echo "$outputDir/file1/txt was not copied [TEST FAILED]"
fi

if [ -f $outputDir/sub1/file3.txt ]
then
        echo "$outputDir/sub1/file3.txt copied [TEST PASSED]"
else
        echo "$outputDir/sub1/file3.txt was not copied [TEST FAILED]"
fi

if [ -f $outputDir/sub1/sub2/file4.txt ]
then
        echo "$outputDir/sub1/sub2/file4.txt copied [TEST PASSED]"
else
        echo "$outputDir/sub1/sub2/file4.txt was not copied [TEST FAILED]"
fi

