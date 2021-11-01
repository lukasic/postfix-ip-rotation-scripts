#!/bin/bash

/etc/postfix/bin/check_blacklist.sh rebuild
/etc/postfix/bin/rebuild_transport.sh
