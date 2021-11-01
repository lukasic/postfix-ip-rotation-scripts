#!/bin/bash


FIRST_CLEAR_IP=`grep " 0$" /etc/postfix/bin/bldb.dat|cut -d " " -f 1|grep -v 198.51.100.103|grep -v 198.51.100.104|head -n 1`
FIRST_CLEAR_IP_COUNT=`grep " 0$" /etc/postfix/bin/bldb.dat|cut -d " " -f 1|grep -v 198.51.100.103|grep -v 198.51.100.104|head -n 1|wc -l`


TMP_FILE=`mktemp`
TRANSPORT_FILE="/etc/postfix/transport_maps"

function update_transport
{

	echo "* relay_${FINAL_IP}" > ${TMP_FILE}

	if ( ! [ -f ${TRANSPORT_FILE} ] ) || ( ! diff ${TRANSPORT_FILE} ${TMP_FILE} >/dev/null ); then
		mv ${TRANSPORT_FILE} ${TRANSPORT_FILE}.old
		mv ${TMP_FILE} ${TRANSPORT_FILE}
		postmap ${TRANSPORT_FILE}
		chmod +r ${TRANSPORT_FILE}
	fi
}


if [ ${FIRST_CLEAR_IP_COUNT} -eq 0 ]; then

	FIRST_IP=`ip -o addr show dev eth0|grep -w inet|egrep -v "brd"|sed -e 's#^.*inet \([0-9\.]*\)/.*$#\1#'|head -n 1`
	FINAL_IP=""`echo ${FIRST_IP} | sed 's/\./_/g'`
	
	update_transport
	exit 0;

else
	FINAL_IP=""`echo ${FIRST_CLEAR_IP} | sed 's/\./_/g'`
	update_transport

fi

if [ -f ${TMP_FILE} ]; then
	rm -f ${TMP_FILE}
fi

