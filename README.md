# chuwi-tablet
A hack to lock the chuwi minibook x keyboard for tablet mode.

After reading the github of sonnyp (https://github.com/sonnyp/linux-minibook-x)

I wanted to give it a try and to get the minibook usable as a convertible.

I verified some of the things I've read on his github and on other places of the www.

cat /sys/devices/platform/INT33D3:00/uevent
returns: MODALIAS=acpi:INT33D3:PNP0C60:

This confirms that the switch is indeed on that address but not readable by linux and not recognised because the way the laptop identifies,

sudo dmidecode -s "chassis-type"
returns: Notebook

sudo cat /sys/class/dmi/id/chassis_type 
returns: 10

So this is where we want to see 31 or 32, and this should be set to the right value in the BIOS bu Chuwi.

So I had to come up with a work around. First I needed to disable the touchpad. This was an easy call because Fn+Esc worked and did the trick.

Now I had to find a way to lock the keyboard. This was aa bit more of a hassle because we now use XWayland instead of X11, so using xinput is not an option anymore.

After some research there seemed to be a 'hack' around. You can use evtest to capture (grab) all the input from an event. I did some testing and it worked, but you had to be root and keep a terminal open. 

Time to find another way, and this is where it get's slightly nasty but it works.

I created a systemd service that monitors a file in /tmp (So if we screw up all we need is a reboot)
I also created a gnome extension that writes to this file, that way we can toggle the keyboard on and off.

All the code is on this github

-----

How to get it all working:

First install some apt packages (remember we are going to run a 6.9 mainline kernel)
I followed this tutorial (https://9to5linux.com/you-can-now-install-linux-kernel-6-8-on-ubuntu-heres-how)

sudo add-apt-repository ppa:cappelikan/ppa
sudo apt update && sudo apt full-upgrade
sudo apt install -y mainline

I enabled rc versions of the kernel and picked the latest available. I did a reboot and installed some more packages that we need for the on screen keyboard and to 'block' the keyboard.

sudo apt install gnome-kiosk evtest systemd-container

------

Now we are ready to install the gnome extension. 

Copy the folder 'kbdlock@local.host' to ~/.local/share/gnome-shell/extensions/

Log out and log in again, use the gnome extension manager and enable the module 'KBDLock'

-------

Now we need to install the service and the scripts. 

AS ROOT!

Copy the folder kbdlock to /opt.
Go into the folder and 'chmod a+x *' on all the files.

Then copy the file 'kbdlock.service' to /lib/systemd/system/

do a 'systemctl daemon-reload' and next 'systemctl start kbdlock.service' 

Now the buttton in the gnome extension should work. If you confirmed it all working you can 'systemctl enable kbdlock.service' to have this 'hack' working until there is a proper solution.

---------

The next step will be a bit more involved, we also want to have the button on the 'gdm login screen'.
I found out the hard way that if the keyboard is locked and you logout, that you can't just enable it.

To install the module for the gdm user, we need to follow the next steps

AS ROOT!

machinectl shell gdm@ /bin/bash

You are now in the shell of the gdm user. (Handle with care)

dconf reset -f /

cd .local/share/gnome-shell/
mkdir extensions
cd extensions
pwd

You will now probably see a path much like

/var/lib/gdm3/.local/share/gnome-shell/extensions



Now open a second terminal and copy the extension folder (kbdlock@local.host) to 

/var/lib/gdm3/.local/share/gnome-shell/extensions (The path we just got from the 'gdm' terminal)

And set the ownership

chown -R gdm:gdm /var/lib/gdm3/.local/share/gnome-shell/extensions

You can now close the root terminal and go back to the 'gdm' terminal

Here we type the following

gsettings set org.gnome.shell enabled-extensions "['kbdlock@local.host']"

And again we can close that terminal to. If everything went right, you have the lock button in the login screen too.


--------

Happy hacking, and have fun using the minibook as a tablet.

