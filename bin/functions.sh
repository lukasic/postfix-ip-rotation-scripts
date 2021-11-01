function list_all_addresses() {
  [ $# -ne 1 ] && return
  ip -o addr show dev eth0|grep -w inet|egrep -v "brd 198.51.100.255"|sed -e 's#^.*inet \([0-9\.]*\)/.*$#\1#' | egrep -v '198.51.100.101'
}

function resolve_addresses() {
  for addr in ${RAW_ADDRESSES}; do
    ptr=`resolve_ptr ${addr}`
    [ -n "${ptr}" ] && echo "${addr} ${ptr}"
  done
  unset addr ptr
}

function resolve_ptr() {
  [ $# -ne 1 ] && return
  IP="$1"
  PTR="`host -t PTR ${IP} 2>/dev/null`"
  [ $? -ne 0 ] && echo "WARNING: IP ${IP} ignored - missing PTR" >&2 && return
  PTR=${PTR##*pointer }
  PTR=${PTR%.}
  echo "${PTR}"
}
