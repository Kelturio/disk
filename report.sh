#!/bin/bash

function pause(){
   read -p 'Press [Enter] key to continue...' ; clear
}

[ "$1" != "" ] && disk=$1 || read -p 'dev disk: ' disk
[ "$2" != "" ] && dt=$2 || read -p 'dev tag: ' dt

id=$(ls -alFR /dev/disk/by-id | grep "/$disk" | awk '{print $9}' | head -n 1)
wd=$(pwd)

[ -d "./by-id/$id" ] || mkdir -pv "./by-dt/$dt"

dir="$wd/by-id/$id"

[ ! -L "$dir" ] && ln -rs "$wd/by-dt/$dt" "$wd/by-id/$id"

sudo rm "./by-id/$id/tree -a"*.txt "./by-id/$id/tree -a"*.json "./by-id/$id/tree -a"*.htm

echo $dt | tee "./by-id/$id/$dt.id.txt" | bat
ls -alFR /dev/disk | grep "/$disk" | awk '{print $9" "$10" "$11}' | tee -a "./by-id/$id/$dt.id.txt" | bat
#pause
#sudo hdparm -I /dev/$disk 2>&1 | tee "./by-id/$id/hdparm -I.txt" | bat
#pause
sudo smartctl -a /dev/$disk 2>&1 | tee "./by-id/$id/smartctl -a.txt" | bat --paging never
##pause
sudo smartctl -x /dev/$disk 2>&1 | tee "./by-id/$id/smartctl -x.txt" | bat
#pause
sudo smartctl -P show /dev/$disk 2>&1 | tee "./by-id/$id/smartctl -P show.txt" | bat
#pause
inxi -Dopluxxx | grep -A 0 "/dev/$disk " | tee "./by-id/$id/inxi -Dopluxxx.txt" | bat
inxi -Dopluxxx | grep -A 1 "/dev/$disk[0-9]" | tee -a "./by-id/$id/inxi -Dopluxxx.txt" | bat
#pause
df -hP /dev/$disk* | grep -v "udev " | tee "./by-id/$id/df -hP.txt" | bat
#pause
mount -l 2>&1 | grep "/dev/$disk" | tee "./by-id/$id/mount -l.txt" | bat
#pause
cols="KNAME,MOUNTPOINT,UUID,FSTYPE,SIZE,MIN-IO,PHY-SEC,LOG-SEC,ROTA,TYPE,WWN,TRAN,LABEL,MODEL,SERIAL"
lsblk -lo $cols /dev/$disk | tee "./by-id/$id/lsblk -lo.txt" | bat
#pause
sed '1d' "./by-id/$id/lsblk -lo.txt" | while read -r line ; do
	fs_kname=$(awk '{print $1}' <<< "$line")
	fs_mountpoint=$(lsblk -no MOUNTPOINT /dev/$fs_kname | head -n 1)
	echo "$fs_mountpoint"
	[ -z "$fs_mountpoint" ] && continue
	fs_uuid=$(lsblk -no UUID /dev/$fs_kname)
	fs_part=$(sed "s/$disk//" <<< "$fs_kname")
#	fs_dmc=$(cut -c1-3 <<< "$fs_kname")
	echo "$fs_part $fs_dmc"
#	[ "$fs_dmc" == "dm-" ] && disk=$1 || read -p 'dev disk: ' disk
#	if [ "$fs_dmc" == "dm-" ]; then
	if [ $(cut -c1-3 <<< "$fs_kname") == "dm-" ]; then
		#printf 'Option -l "%s" specified\n' "$lval"
		fs_name=$(lsblk -no NAME /dev/$fs_kname | head -n 1)
		echo "fs_name $fs_name"
		fs_puuid=$(sed "s/luks-//" <<< "$fs_name")
		echo "fs_puuid $fs_puuid"
		ls -lha /dev/disk/by-uuid
	fi
#	tree -a "$fs_mountpoint" 2>&1 | tee "./by-id/$id/tree -a p$fs_part $fs_uuid.txt" | bat --paging never
#	tree -afi "$fs_mountpoint" 2>&1 | tee "./by-id/$id/tree -afi p$fs_part $fs_uuid.txt" | bat --paging never
#	tree -adfi "$fs_mountpoint" 2>&1 | tee "./by-id/$id/tree -adfi p$fs_part $fs_uuid.txt" | bat --paging never
#	tree -aJ "$fs_mountpoint" 2>&1 | tee "./by-id/$id/tree -aJ p$fs_part $fs_uuid.json" | bat --paging never
#	tree -apugsDJ --inodes --device "$fs_mountpoint" 2>&1 | tee "./by-id/$id/tree -apugsDJ --inodes --device p$fs_part $fs_uuid.json"  | bat --paging never
	cd "$fs_mountpoint"
#	tree -aH "$fs_mountpoint" 2>&1 | tee "$wd/by-id/$id/tree -aH p$fs_part $fs_uuid.htm" #| bat --paging never
	cd "$wd"
done

#sudo smartctl -l error /dev/sdb
#sudo smartctl -l selftest /dev/sdb
#sudo smartctl -l devstat /dev/sdc
