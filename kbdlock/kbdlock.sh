#! /bin/bash -

# We need to test if we have both sensors
# if not we need to add the second one
# Both should exist (Thanks to https://github.com/sleeply4cat for pointing me in this direction)

# /sys/bus/iio/devices/iio:device0/in_accel_x_raw (Lid)
# /sys/bus/iio/devices/iio:device1/in_accel_x_raw (Base)
#
# echo mxc4005 0x15 > /sys/bus/i2c/devices/i2c-0/new_device

if ! grep -q 0 "/sys/bus/iio/devices/iio:device1/in_accel_x_raw"; then
   echo mxc4005 0x15 > /sys/bus/i2c/devices/i2c-0/new_device
fi

# For this script we assume that /tmp exist and is writable
PIDFILE="/tmp/kbdlock.pid"
STATEFILE="/tmp/kbdlock.state" 
CURRENTSTATE=0
KBDEVENT=`ls /dev/input/by-path/ -la | grep kbd | awk '{print $NF}' | sed "s/..\///"`

# rm is only for a restart of the service
# Create a fresh pid file
rm $PIDFILE
echo "" > $PIDFILE
chmod 777 $PIDFILE

# Create a fresh state file
rm $STATEFILE
echo 0 > $STATEFILE
chmod 777 $STATEFILE

# Make lock and unlock function
function kbd_lock {
    echo "State changed to 1"
    evtest --grab "/dev/input/$KBDEVENT" > /dev/null &pid=$!
    echo $pid > $PIDFILE
}

function kbd_unlock {
  echo "State changed to 0"
  cat "$PIDFILE" | xargs kill -9 >/dev/null 2>&1
  #kill -9 `cat "$PIDFILE"` > /dev/null 2>&1
  echo "" > $PIDFILE
}

while true
do
    # Here we create an endless loop to test the state file.
    # if it contains a 0 the keyboard should not be locked
    # if it contains a 1 the keyboard should be locked
    if grep -q 0 "$STATEFILE"; then
        if [ $CURRENTSTATE = 1 ]; then
            # State changed to 0
            # We will unlock the keyboard here
            kbd_unlock
            # and we change the state to the new current state
            CURRENTSTATE=0
        fi
    else
        if [ $CURRENTSTATE = 0 ]; then
            # State changed to 1
            # We will lock the keyboard here
            kbd_lock
            # and we change the state to the new current state
            CURRENTSTATE=1
        fi
    fi
  sleep 1
done
