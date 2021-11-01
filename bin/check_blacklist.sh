#!/bin/bash
set -e

SELF=$(readlink -f ${0})
: ${BLDB:=${SELF%/*}/bldb.dat}
BLDBOVERVIEW=$BLDB.overview
BLDBOVERVIEWTMP=$BLDB.overview.tmp
BLDBTMP=$BLDB.tmp
BLDBGOOGLE=$BLDB.google
BLDBLIVECOM=$BLDB.livecom
BLDBCOBION=$BLDB.cobion
BLDBPROOFPOINT=$BLDB.proofpoint
BLDBATT=$BLDB.att
BLDBUNKNOWN=$BLDB.unknown
BLDBMICROSOFT=$BLDB.microsoft
BLDBMICROSOFT2=$BLDB.microsoft2
BLDBYAHOO=$BLDB.yahoo
#BLDSMAMCOP=$BLDB.spamcop

##########[ INCLUDE LIBRARIES ]##########
[ -r "${SELF%/*}/functions.sh" ] && source "${SELF%/*}/functions.sh"

: ${DEVICE:="eth0"}
ADDRESSES=${FORCE_USE_ADDRESSES:-"`list_all_addresses $DEVICE`"}

##########[ FUNCTIONS ]##########
function rebuild_bldb() {
  [ -e "${BLDBTMP}" ] && echo "ERROR: tmpfile (${BLDBTMP}) exists." && exit 10
  exec 4>>${BLDBTMP}
  tail -n 100000 /var/log/mail.log | grep "unsolicited mail originating from your IP address" | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq > $BLDBGOOGLE
  tail -n 100000 /var/log/mail.log | grep "weren't sent. Please contact your Internet service provider since part of their network is on our block list" | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq > $BLDBLIVECOM
  tail -n 100000 /var/log/mail.log | grep 'See http://att.net/blocks' | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq > $BLDBATT
  tail -n 100000 /var/log/mail.log | grep 'ESMTP Blocked - see https://support.proofpoint.com/dnsbl-lookup.cgi?ip=' | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq > $BLDBPROOFPOINT
  tail -n 100000 /var/log/mail.log | grep "for more information, please visit http://filterdb.iss.net/dnsblinfo" | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq > $BLDBCOBION
  tail -n 100000 /var/log/mail.log | grep "550-Message rejected because .* is blacklisted" | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq  > $BLDBUNKNOWN
  tail -n 100000 /var/log/mail.log | grep 'blocked using Blocklist 1, mail from IP banned; To request removal from this list please forward this message' | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq > $BLDBMICROSOFT
#  tail -n 100000 /var/log/mail.log | grep 'blocked using bl.spamcop.net' | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq > $BLDBSPAMCOP
  tail -n 100000 /var/log/mail.log | grep 'Server busy. Please try again later from' | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq > $BLDBMICROSOFT
  tail -n 50000 /var/log/mail.log | grep 'temporarily deferred due to user complaints - 4.16.55.1' | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq > $BLDBYAHOO
  tail -n 100000 /var/log/mail.log | grep 'Access denied, banned sending IP' | egrep -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq > $BLDBMICROSOFT2

  for ip in ${ADDRESSES}; do
    IPTEMP=`mktemp /tmp/RBL$ip.XXXXX`
    ${SELF%/*}/check_rbl --extra-opts=rbl@${SELF%/*}/check_rbl.ini -t 120 -H "${ip}" -v -r 4 |tee > $IPTEMP
#    ${SELF%/*}/extra/check_trendmicro ${ip} >> $IPTEMP
    ${SELF%/*}/extra/check_hostkarma.junkemailfilter.com ${ip} >> $IPTEMP
#    if cat $BLDBGOOGLE | grep -q "^$ip$" ; then
#       echo listed in google >> $IPTEMP
#    else
#       echo not listed in google >> $IPTEMP
#    fi

    if cat $BLDBLIVECOM | grep -q "^$ip$" ; then
        echo listed in live.com >> $IPTEMP
    else
        echo not listed in live.com >> $IPTEMP
    fi

    if cat $BLDBATT | grep -q "^$ip$" ; then
        echo listed in att.com >> $IPTEMP
    else
        echo not listed in att.com >> $IPTEMP
    fi

    if cat $BLDBCOBION | grep -q "^$ip$" ; then
        echo listed in cobion >> $IPTEMP
    else
        echo not listed in cobion >> $IPTEMP
    fi

    if cat $BLDBPROOFPOINT | grep -q "^$ip$" ; then
        echo listed in proofpoint.com >> $IPTEMP
    else
        echo not listed in proofpoint.com >> $IPTEMP
    fi

    if cat $BLDBUNKNOWN | grep -q "^$ip$" ; then
        echo listed in unknown >> $IPTEMP
    else
        echo not listed in unknown >> $IPTEMP
    fi

    if cat $BLDBMICROSOFT | grep -q "^$ip$" ; then
        echo listed in microsoft >> $IPTEMP
    else
        echo not listed in microsoft >> $IPTEMP
    fi

    if cat $BLDBMICROSOFT2 | grep -q "^$ip$" ; then
        echo listed in microsoft2 >> $IPTEMP
    else
        echo not listed in microsoft2 >> $IPTEMP
    fi

#    if cat $BLDBSPAMCOP | grep -q "^$ip$" ; then
#        echo listed in bl.spamcop.net >> $IPTEMP
#    else
#        echo not listed in bl.spamcop.net >> $IPTEMP
#    fi

    if cat $BLDBYAHOO | grep -q "^$ip$" ; then
        echo listed in yahoo >> $IPTEMP
    else
        echo not listed in yahoo >> $IPTEMP
    fi

    count=`cat $IPTEMP | grep -c -E "^listed in "`
    listings=`cat $IPTEMP | grep "^listed in " | cut -d ' ' -f 3 | tr '\n' ' '`
    rm $IPTEMP

	echo "${ip} ${count} ${listings}"
    echo "${ip} ${count}" >&4
    echo "${ip} ${count} ${listings}" >> $BLDBOVERVIEWTMP
  done
  exec 4>&-
  mv -f "${BLDBTMP}" "${BLDB}"
  mv -f "${BLDBOVERVIEWTMP}" "${BLDBOVERVIEW}"
}

function get_status() {
  grep -E "^[ 	]*${1//./\.}[	 ]" ${BLDB} | { while read ip status; do echo $(( status )); done } | tail -1
}

##########[ MAIN ]##########
[ $# -eq 0 ] && echo -e "Nothing to do.\nUsage: ${0##*/} [ rebuild | status <ip> ]" && exit
while [ $# -gt 0 ]; do
	  [ ${1,,} = "rebuild" ] && shift && rebuild_bldb && continue
  [ ${1,,} = "status" -a $# -ge 2 ] && get_status ${2} && shift 2 && continue
  echo "ERROR(${SELF}): Invalid parameter(s) on command line: '$@'" >&2 && exit 1
done
