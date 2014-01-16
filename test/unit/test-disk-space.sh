#!/bin/bash

#get available space on the 
availableSpace=$(../lib/lib.sh getAvailableDiskSpace /tmp)
minSpace=300
echo "available Space: '$availableSpace MB'"
echo "minimum space: $minSpace MB"

if [ "$availableSpace" = "" ]
then
	#if returned space is empty string then just return nothing
	exit
fi

if [ $availableSpace -gt $minSpace ];
then
	echo $availableSpace
else
	echo 0
fi

