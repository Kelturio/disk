#!/bin/bash

function pause(){
   read -p 'Press [Enter] key to continue...' ; clear
}

[ "$1" != "" ] && disk=$1 || read -p 'dev disk: ' disk
[ "$2" != "" ] && dt=$2 || read -p 'dev tag: ' dt

id=$(ls -alFR /dev/disk/by-id | grep "/$disk" | awk '{print $9}' | head -n 1)
wd=$(pwd)

[ -d "./by-id/$id" ] || mkdir -pv "./by-dt/$dt"
#[ -d "./by-id/$id" ] || mkdir -pv "./by-id/$id"
#mkdir -pv "./by-id/$id"

dir="$wd/by-id/$id"

#[ ! -L "$dir" ] && ln -s "$wd/by-id/$id" "$wd/by-dt/$dt"
[ ! -L "$dir" ] && ln -rs "$wd/by-dt/$dt" "$wd/by-id/$id"

rm "./by-id/$id/tree -a"*.txt "./by-id/$id/tree -a"*.json "./by-id/$id/tree -a"*.htm

echo $dt | tee "./by-id/$id/$dt.id.txt"
ls -alFR /dev/disk | grep "/$disk" | awk '{print $9}' | tee -a "./by-id/$id/$dt.id.txt"
pause
sudo hdparm -I /dev/$disk 2>&1 | tee "./by-id/$id/hdparm -I.txt"
pause
sudo smartctl -a /dev/$disk 2>&1 | tee "./by-id/$id/smartctl -a.txt"
sudo smartctl -x /dev/$disk 2>&1 | tee "./by-id/$id/smartctl -x.txt"
sudo smartctl -P show /dev/$disk 2>&1 | tee "./by-id/$id/smartctl -P show.txt"
pause
inxi -Dopluxxx | grep -A 0 "/dev/$disk " | tee "./by-id/$id/inxi -Dopluxxx.txt"
inxi -Dopluxxx | grep -A 1 "/dev/$disk[0-9]" | tee -a "./by-id/$id/inxi -Dopluxxx.txt"
pause
df -hP /dev/$disk* | grep -v "udev " | tee "./by-id/$id/df -hP.txt"
pause
mount -l | grep "/dev/$disk" | tee "./by-id/$id/mount -l.txt"
pause
cols="NAME,MOUNTPOINT,UUID,FSTYPE,SIZE,MIN-IO,PHY-SEC,LOG-SEC,ROTA,TYPE,WWN,TRAN,LABEL,MODEL,SERIAL"
lsblk -lo $cols /dev/$disk | tee "./by-id/$id/lsblk -lo.txt"
pause
sed '1d' "./by-id/$id/lsblk -lo.txt" | while read -r line ; do
	fs_name=$(awk '{print $1}' <<< "$line")
	fs_mountpoint=$(lsblk -no MOUNTPOINT /dev/$fs_name | head -n 1)
	echo "$fs_mountpoint"
	[ -z "$fs_mountpoint" ] && continue
	fs_uuid=$(lsblk -no UUID /dev/$fs_name)
	fs_part=$(sed "s/$disk//" <<< "$fs_name")
	tree -a "$fs_mountpoint" 2>&1 | tee "./by-id/$id/tree -a p$fs_part $fs_uuid.txt"
	tree -afi "$fs_mountpoint" 2>&1 | tee "./by-id/$id/tree -afi p$fs_part $fs_uuid.txt"
	tree -adfi "$fs_mountpoint" 2>&1 | tee "./by-id/$id/tree -adfi p$fs_part $fs_uuid.txt"
	tree -aJ "$fs_mountpoint" 2>&1 | tee "./by-id/$id/tree -aJ p$fs_part $fs_uuid.json"
	tree -apugsDJ --inodes --device "$fs_mountpoint" 2>&1 | tee "./by-id/$id/tree -apugsDJ --inodes --device p$fs_part $fs_uuid.json"
	cd "$fs_mountpoint"
	tree -aH "$fs_mountpoint" 2>&1 | tee "$wd/by-id/$id/tree -aH p$fs_part $fs_uuid.htm"
	cd "$wd"
done

#sudo smartctl -l error /dev/sdb
#sudo smartctl -l selftest /dev/sdb
#sudo smartctl -l devstat /dev/sdc
