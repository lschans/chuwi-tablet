# Chuwi-Tablet: Convertible Mode Activation Hack

Unlock the potential of your Chuwi Minibook X (and probably other Chinese convertible laptops) by enabling tablet mode through a simple workaround.

Inspired by the work of [Sonnyp on GitHub](https://github.com/sonnyp/linux-minibook-x) and with help and research from [sleepy4cat](https://github.com/sleeply4cat), I embarked on a journey to transform my cute little laptop into a fully functional convertible device using userspace code.

*(Mostly because I don't have the illusion that Chuwi will fix the BIOS for us.)*

## Understanding the Challenge

Upon investigating, I discovered that the Minibook's *'convertible mode switch'* wasn't readily accessible by Linux in kernel space. ['SonnyP'](https://github.com/sonnyp) found out that when using Windows there is an ACPI device at address **'INT33D3:PNP0C60'** 

To verify if this device exist I tried the following as root.


```bash
cat /sys/devices/platform/INT33D3:00/uevent
```

***Which returns:** MODALIAS=acpi:INT33D3:PNP0C60:*

While this confirmed the switch's address, Linux couldn't recognize it because the Minibook identified as a "Notebook" rather than a convertible device.

Running the following commands as root gives a more clear example of what's happening below.

```bash
sudo dmidecode -s "chassis-type"
```

***returns:** Notebook*

```bash
sudo cat /sys/class/dmi/id/chassis_type 
```

***returns:** 10*

In a better world, this is where we want to see 31 or 32, and convertilbe. But unfortunately this needs be set to the right value in the BIOS, not by us, but by Chuwi.

## Inventing and Crafting a Solution

Since kernelspace wasn't going to provide us with an answer to our problem, not even after upgrading to the release candidate of the 6.9 kernel I decided to solve the problem from userspace.

I will explain every step I took as good as possible to make you understand what we are doing. This way, if it ever get's fixed you should be able to reverse the complete process.

### Step 1: Disabling Touchpad
Fortunately, disabling the touchpad was straightforward using Fn+Esc. *(One of the few things that did work out of the box.)*

### Step 2: Making the accelerometer work.

For this step there is not much we have to do exept for upgrading to Linux kernel 6.9. Since I am writing this manual at kernel version 6.8 and 6.9 is not released yet. I installed a mainline release candidate but if 6.9 or newer is out, you should skip tis step. *(I know bad practise to use rc kernels, but for me it's not my main laptop)*

Luckily for us our friend Cappelikan has a repo with mainline kernels so I followed [a 9to5linux tutorial](https://9to5linux.com/you-can-now-install-linux-kernel-6-8-on-ubuntu-heres-how) that explains it all.

The steps to follow if you don't want to read the tutorial are in short:

```bash
sudo add-apt-repository ppa:cappelikan/ppa
sudo apt update && sudo apt full-upgrade
sudo apt install -y mainline
```

After this we have the 'mainline kernels' GUI app.

* Go to settings
* Disable 'hide rc versions'
* Install the latest version
* Reboot

At this point the accelerometer should work and we can verify this by opening a root shell and running the following **long** command.

```bash
watch -n 0.5 '
cat /sys/bus/iio/devices/iio:device0/in_accel_scale_available &&
cat /sys/bus/iio/devices/iio:device0/in_accel_x_raw &&
cat /sys/bus/iio/devices/iio:device0/in_accel_y_raw &&
cat /sys/bus/iio/devices/iio:device0/in_accel_z_raw'
```

If you wiggle the laptop around you should see the numbers change. (press CTRL+C to exit watch)

To 'tune' the sensor we need to add a line to the system configuration. So as root run the following code. *(The space indentation on the second line is there on purpose)*

```bash

echo "sensor:modalias:acpi:/dev/iio-device0
 ACCEL_MOUNT_MATRIX=0, 1, 0; 1, 0, 0; 0, 0, 1" >> /etc/udev/hwdb.d/61-sensor-local.hwdb

echo "sensor:modalias:acpi:/dev/iio-device1
 ACCEL_MOUNT_MATRIX=0, 1, 0; 1, 0, 0; 0, 0, 1" >> /etc/udev/hwdb.d/61-sensor-local.hwdb

```

And reboot.

### Step 3: Making the laptop rotate the screen.

Let's start by installing an extension that's already around and is doing a great job. (https://github.com/shyzus/gnome-shell-extension-screen-autorotate)

This extension already adds a lot of the features for screen rotation. It's a very simple to use piece of software just click around in it and configure it to your likes. I had to convert the horizontal axis to make it work. And I enabled the on screen keyboard for all axis except the 'normal laptop mode'

To make the OSK (On Screen Keyboard) work, if it doesn't install the gnome-kiosk package.

```bash
sudo apt install -y gnome-kiosk
```

Again play around with it a bit, and slowly see it all coming together.

### Step 4: Disable the keyboard.

**This was a pain to accomplish!**

Since we live in modern days and we are using XWayland we can't just use the old fashioned ways and disable some hardware using *'xinput'*

So again I had to find a solution to make it work. There is a small application the lets you test input devices. It's called ***evtest*** and some of you might know it. 

Evtest has a mode where it 'grabs' all the input for testing purposes and we are going to abuse this mode to prevent keyboard input being send to Wayland.

So we need to install some packages again.

```bash
sudo apt install evtest -y
```

When you run evtest as root, it will show you all your input devices, and gives you the ability to test them. If this works, you are ready for the next few steps.

### Step 5: Running it as a service.

Since we need to run evtest as root. *(even after adding my user account to the 'input' group)* and because we eventually want this to happen automatically. I decided to make a simple 'bash script as a service'.

This service needs to do a few things:
* Start the evtest application in the background
* Kill the evtest application
* And know when to kill or to start it

To do so I create 2 text files in /tmp. The reason for this decision is that if we screw up, we can just reboot the laptop /tmp will be empty and everything will work as normal.

The script and the service are in the repo and are commented. I will just show you how to install the service. At this point I assume that you cloned the repo, and that you are in the folder of the repo.

As root we run the following commands:

```bash
cp -r kbdlock /opt
chmod -R a+x /opt/kbdlock
cp systemd/kbdlock.service /lib/systemd/system/
systemctl daemon-reload
```

Now we can start the service (still as root)

```bash
systemctl start kbdlock.service
```

If we don't have any errors we run the test and verify that the keyboard gets disabled for 10 seconds

```bash
/opt/kbdlock/enable.sh; sleep 10; /opt/kbdlock/disable.sh
```

If your keyboard didn't work for 10 seconds you are good to go and you can enable the service. (as root)

```bash
systemctl enable kbdlock.service
```

### Step 6: An extension to control the service.

If you made it to this point, you are a boss! Give yourself a pat on the back because even I think it's getting boring. But we are almost there.

We need a way to enable or disable the feature from gnome. This way it gets usable and we can finally use our sweet Minibook as a tablet.

From the root of the project we are going to copy our extension to the extensions folder in our userprofile.

```bash
cp kbdlock@local.host ~/.local/share/gnome-shell/extensions/
```

Now reboot, or log in and out, basically whatever you please. Go to the extension manager in gnome and enable the module.

After enabling the module you will notice that we have an extra button in the taskbar menu. It has the icon of a tablet and the text 'KBD Locked'

If we enable the feature, the keyboard locks. If we disable it, the keyboard unlocks.

Yay, we have a working tablet. But are we there yet? No!

### Step 7: Add the extension to the login screen.

This step is a bit involved, and we need to play a bit around with the GDM user. **If you follow the steps exactly** there is not much that can go wrong.

First we need to install another package

```bash
sudo apt install systemd-container -y
```

Now make sure to have 2 root terminals open. We will need both of them at the same time.

In the first terminal we run the following command.

```bash
machinectl shell gdm@ /bin/bash
```

You are now in the shell of the GDM user.

In this GDM shell we run the following commands:

```bash
dconf reset -f /

cd .local/share/gnome-shell/
mkdir extensions
cd extensions
pwd
```

The last command the 'pwd' returns a path. 
Probably something like '/var/lib/gdm3/.local/share/gnome-shell/extensions'
We need this path in the other terminal.

So in the other terminal we are going to copy the extension to the GDM users extension folder. *Change the path in the command if your path wasn't '/var/lib/gdm3/.local/share/gnome-shell/extensions' to the output of the 'pwd' in the other terminal.*

And run the following commands:

```bash
cp kbdlock@local.host /var/lib/gdm3/.local/share/gnome-shell/extensions

chown -R gdm:gdm /var/lib/gdm3/.local/share/gnome-shell/extensions
```

We have now copied the extension to the GDM users folder. And we can close this terminal. We still need to keep the other 'GDM terminal' open because we need to enable it.

So as the GDM user we now run:

```bash
gsettings set org.gnome.shell enabled-extensions "['kbdlock@local.host']"
```

You can now exit this terminal and reboot the system again, because we are done. We have our lock button in the login screen, and in our user account.

For now if there are more users using the same machine, you need to install the extension to their profile too. Just the extension, not the service.

Keep an eye on this page, I am still working on some improvements.

---

Happy hacking, and have fun using the minibook as a tablet.

