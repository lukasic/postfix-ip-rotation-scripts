#!/bin/bash
IP=$1
IP_REV=`echo $IP | sed -r 's/([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/\4.\3.\2.\1/g'`
HOST="$IP_REV.hostkarma.junkemailfilter.com"
if dig $HOST | grep -q '127.0.0.2' ; then
	echo 'listed in hostkarma.junkemailfilter.com'
else
	echo 'not listed in hostkarma.junkemailfilter.com'
fi
