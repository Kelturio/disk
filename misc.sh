#!/bin/bash


# 
sudo smartctl -l error /dev/sdb
sudo smartctl -l selftest /dev/sdb
sudo smartctl -l devstat /dev/sdc


# dist upgrade
sudo -s <<< 'apt update -y && apt dist-upgrade -y'


# Check for less, install if needed:
dpkg -l | grep -qw less || sudo apt install -yyq less


# symlink src target in homedir
s="$HOME/Git/disk/report.sh";t="$HOME/bin/report.sh";echo "$s $t";[ ! -L "$t" ] && ln -s "$s" "$t" 2>&1 | bat


# Don't allow running as root
if [ "$(id -u)" == "0" ]; then
	show_message --error $"Cannot run as root user"
	exit 1
fi


hwinfo
