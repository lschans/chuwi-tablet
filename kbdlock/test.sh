#! /bin/bash -

# Test script for the keyboard lock
# This script will lock the keyboard for 10 seconds

# If your keyboard doesn't lock, you did something wrong.
# If the keyboard doesn't unlock reboot your Minibook holding the power button
# Or use the touchscreen to reboot.

echo 1 > /tmp/kbdlock.state
echo "Keyboard is locked"
sleep 10
echo 0 > /tmp/kbdlock.state
echo "Keyboard is unlocked"