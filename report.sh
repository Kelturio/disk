#!/bin/bash

function pause(){
   read -p 'Press [Enter] key to continue...' ; clear
}

[ "$1" != "" ] && disk=$1 || read -p 'dev disk: ' disk
[ "$2" != "" ] && dt=$2 || read -p 'dev tag: ' dt

id=$(ls -alFR /dev/disk/by-id | grep "/$disk" | awk '{print $9}' | head -n 1)
cwd=$(pwd)
lwd="$cwd/by-dt/$dt"
iwd="$cwd/by-id/$id"

StringArray=("$lwd/$dt.id.txt" "$lwd/inxi -Dopluxxx.txt" "$lwd/df -hP.txt" "$lwd/mount -l.txt" "$lwd/lsblk -lo.txt")

echo -e "\$disk\t= $disk\n\$dt \t= $dt\n\$id \t= $id\n\$cwd\t= $cwd\n\$lwd\t= $lwd\n\$iwd\t= $iwd\n" | bat

[ -d "$lwd/tree" ] || mkdir -pv "$lwd/tree" 2>&1 | bat
[ ! -L "$iwd" ] && ln -rs "$lwd" "$iwd" 2>&1 | bat

rm "$lwd/tree -a"*.txt "$lwd/tree -a"*.json "$lwd/tree -a"*.htm 2>&1 | bat

log="$lwd/$dt.id.txt" ; { echo $dt ; ls -alFR /dev/disk | grep "/$disk" | awk '{print $9" "$10" "$11}' ; } | tee > "$log" ; bat --highlight-line 1 "$log"
#pause
log="$lwd/hdparm -I.txt" ; sudo hdparm -I /dev/$disk 2>&1 | tee > "$log" ; bat "$log"
#pause
log="$lwd/smartctl -a.txt" ; sudo smartctl --all /dev/$disk 2>&1 | tee > "$log" ; bat --paging never "$log"
##pause
log="$lwd/smartctl -x.txt" ; sudo smartctl --xall /dev/$disk 2>&1 | tee > "$log" ; bat "$log"
#pause
log="$lwd/smartctl -P show.txt" ; sudo smartctl --presets=show /dev/$disk 2>&1 | tee > "$log" ; bat "$log"
#pause
log="$lwd/inxi -Dopluxxx.txt" ; { inxi -Dopluxxx | grep -A 0 "/dev/$disk " ; inxi -Dopluxxx | grep -A 1 "/dev/$disk[0-9]" ; } | tee > "$log" ; bat "$log"
#pause
log="$lwd/df -hP.txt" ; df -hP /dev/$disk* | grep -v "udev " | tee > "$log" ; bat "$log"
#pause
log="$lwd/mount -l.txt" ; mount -l 2>&1 | grep "/dev/$disk" | tee > "$log" ; bat "$log"
#pause
cols="KNAME,MOUNTPOINT,UUID,FSTYPE,SIZE,MIN-IO,PHY-SEC,LOG-SEC,ROTA,TYPE,WWN,TRAN,LABEL,MODEL,SERIAL"
log="$lwd/lsblk -lo.txt" ; lsblk -lo $cols /dev/$disk | tee > "$log" ; bat "$log"
#pause
sed '1d' "$lwd/lsblk -lo.txt" | while read -r line ; do
	fs_kname=$(awk '{print $1}' <<< "$line")
	echo "$line"
	fs_mountpoint=$(lsblk -no MOUNTPOINT /dev/$fs_kname | head -n 1)
	[ -z "$fs_mountpoint" ] && continue
	fs_uuid=$(lsblk -no UUID /dev/$fs_kname)
	fs_partnr=$(sed "s/$disk//" <<< "$fs_kname")
	if [ $(cut -c1-3 <<< "$fs_kname") == "dm-" ]; then
		fs_name=$(lsblk -no NAME /dev/$fs_kname | head -n 1)
		fs_puuid=$(sed "s/luks-//" <<< "$fs_name")
		fs_partnr="$(blkid --uuid "$fs_puuid" | sed "s=/dev/$disk==")c"
	fi
	echo -e "\$fs_kname\t\t= $fs_kname\n\$fs_mountpoint\t= $fs_mountpoint\n\$fs_uuid\t\t= $fs_uuid\n\$fs_partnr\t\t= $fs_partnr\n\$fs_name\t\t= $fs_name\n\$fs_puuid\t\t= $fs_puuid\n" | bat
	log="$lwd/tree -a p$fs_partnr $fs_uuid.txt" ; tree -a "$fs_mountpoint" 2>&1 | tee > "$log" ; bat --paging never "$log"
	log="$lwd/tree -afi p$fs_partnr $fs_uuid.txt" ; tree -afi "$fs_mountpoint" 2>&1 | tee > "$log" ; bat --paging never "$log"
	log="$lwd/tree -adfi p$fs_partnr $fs_uuid.txt" ; tree -adfi "$fs_mountpoint" 2>&1 | tee > "$log" ; bat --paging never "$log"
	log="$lwd/tree -aJ p$fs_partnr $fs_uuid.json" ; tree -aJ "$fs_mountpoint" 2>&1 | tee > "$log" ; bat --paging never "$log"
	log="$lwd/tree -apugsDJ --inodes --device p$fs_partnr $fs_uuid.json" ; tree -apugsDJ --inodes --device "$fs_mountpoint" 2>&1 | tee > "$log" ; bat --paging never "$log"
	cd "$fs_mountpoint"
	log="$lwd/tree -aH p$fs_partnr $fs_uuid.htm" ; tree -aH "$fs_mountpoint" 2>&1 | tee > "$log" ; bat --paging never --wrap never "$log"
	cd "$cwd"
done

for val in "${StringArray[@]}"; do
  sed -i "s/$disk/sdx/g" "$val"
done

#sudo smartctl -l error /dev/sdb
#sudo smartctl -l selftest /dev/sdb
#sudo smartctl -l devstat /dev/sdc
