#!/bin/bash
source /etc/interface.conf
if [ "$1" == "$PHYSICAL_INTERFACE_IN" ]; then
    /usr/bin/systemctl --no-block restart auto-static-ip.service
fi
