#! /bin/bash -

# For this script we assume that /tmp exist and is writable

STATEFILE="/tmp/kbdlock.state" 

echo "0" > $STATEFILE
