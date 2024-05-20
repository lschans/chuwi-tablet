#!/bin/bash

TRESHOLD=50

function to_pos {
if ! [ "$1" -gt 0 ]; then
	echo -n $(($1*-1))
else
    echo -n $1
fi
}

function is_tablet {
if ! [ "$1" -gt "$TRESHOLD" ]; then
  echo 1
else
  echo 0
fi
}

LID=$(to_pos `cat /sys/bus/iio/devices/iio:device0/in_accel_x_raw`)
BASE=$(to_pos `cat /sys/bus/iio/devices/iio:device1/in_accel_x_raw`)
DIFF=$(to_pos $(($LID-$BASE)) )
TABLET=$(is_tablet $DIFF)

echo "Lid: $LID"
echo "Base: $BASE"
echo "Diff: $DIFF"
echo ""
echo "Is tablet $TABLET"


