#!/bin/bash

word=$1
logfile=$2
curdate=`date`

logger "logwatcher is up and running"
logger "looking for the word $1 in $2 file"

if grep $word $logfile &> /dev/null
then
	logger "$curdate: I found the word!"
else
	exit 0
fi

