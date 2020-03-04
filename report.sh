#!/bin/bash

# Akk Disk Indexer Script -- by Searinox

set -e

echo "Akk Disk Indexer Script"

[ -d "$HOME/Git/disk" ] && cd "$HOME/Git/disk"

pause(){
   read -p 'Press [Enter] key to continue...' ; clear
}

treew(){
#   log="$lwd/tree/tree -a p$fs_partnr $fs_uuid.txt" ; tree -a "$fs_mountpoint" 2>&1 | tee > "$log" ; bat --paging never "$log"
#	tree $2 "$3" 2>&1 | tee > "$1" ; bat --paging never "$1"
	tree -o "$1" $2 "$3" ; bat --paging never "$1"
}

[ "$1" != "" ] && disk=$1 || read -p 'dev disk: ' disk
[ "$2" != "" ] && dt=$2 || read -p 'dev tag: ' dt

id=$(ls -alFR /dev/disk/by-id | grep "/$disk" | awk '{print $9}' | head -n 1)
cwd=$(pwd)
lwd="$cwd/by-dt/$dt"
iwd="$cwd/by-id/$id"

#fna=("$lwd/$dt.id.txt" "$lwd/inxi -Dopluxxx.txt" "$lwd/df -hP.txt" "$lwd/mount -l.txt" "$lwd/lsblk -lo.txt")
declare -a fna

echo -e "\$disk\t= $disk\n\$dt \t= $dt\n\$id \t= $id\n\$cwd\t= $cwd\n\$lwd\t= $lwd\n\$iwd\t= $iwd\n" | bat ; pause

[ -d "$lwd/tree" ] || mkdir -pv "$lwd/tree" 2>&1 | bat
[ ! -L "$iwd" ] && ln -rs "$lwd" "$iwd" 2>&1 | bat

rm "$lwd/tree -a"*.txt "$lwd/tree -a"*.json "$lwd/tree -a"*.htm 2>&1| bat

#lsblk -lnop KNAME /dev/$disk 
log="$lwd/lsblk -lno.tmp" ; lsblk -lno KNAME /dev/$disk | tee > "$log" ; bat "$log"
log="$lwd/lsblk -lnpo.tmp" ; lsblk -lnpo KNAME /dev/$disk | tee > "$log" ; bat "$log"

fna+=("$lwd/$dt.id.txt") ; { echo $dt ; ls -alFR /dev/disk | grep -f "$lwd/lsblk -lno.tmp" | awk '{print $9" "$10" "$11}' ; } | tee > "${fna[0]}" ; bat --highlight-line 1 "${fna[0]}"
#pause
#log="$lwd/hdparm -I.txt" ; sudo hdparm -I /dev/$disk 2>&1 | tee > "$log" ; bat "$log"
#pause
log="$lwd/smartctl -a.txt" ; sudo smartctl --all /dev/$disk 2>&1 | tee > "$log" ; bat --paging never "$log"
##pause
log="$lwd/smartctl -x.txt" ; sudo smartctl --xall /dev/$disk 2>&1 | tee > "$log" ; bat "$log"
#pause
log="$lwd/smartctl -P show.txt" ; sudo smartctl --presets=show /dev/$disk 2>&1 | tee > "$log" ; bat "$log"
#pause
fna+=("$lwd/inxi -Dopluxxx.txt") ; { inxi -Dopluxxx | grep -f "$lwd/lsblk -lnpo.tmp" -A 1 ; } | tee > "${fna[1]}" ; bat "${fna[1]}"
#pause
#fna+=("$lwd/df -hP.txt") ; df -hP /dev/$disk* | grep -v "udev " | tee > "${fna[2]}" ; bat "${fna[2]}"
fna+=("$lwd/df -hP.txt") ; df -hP | grep -f "$lwd/lsblk -lnpo.tmp" | tee > "${fna[2]}" ; bat "${fna[2]}"
#pause
#fna+=("$lwd/mount -l.txt") ; mount -l 2>&1 | grep "/dev/$disk" | tee > "${fna[3]}" ; bat "${fna[3]}"
fna+=("$lwd/mount -l.txt") ; mount -l 2>&1 | grep -f "$lwd/lsblk -lnpo.tmp" "/dev/$disk" | tee > "${fna[3]}" ; bat "${fna[3]}"
#pause
cols="KNAME,MOUNTPOINT,UUID,FSTYPE,SIZE,MIN-IO,PHY-SEC,LOG-SEC,ROTA,TYPE,WWN,TRAN,LABEL,MODEL,SERIAL"
fna+=("$lwd/lsblk -lo.txt") ; lsblk -lo $cols /dev/$disk | tee > "${fna[4]}" ; bat "${fna[4]}"
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
	treew "$lwd/tree/tree -a p$fs_partnr $fs_uuid.txt" "-a" "$fs_mountpoint"
	treew "$lwd/tree/tree -afi p$fs_partnr $fs_uuid.txt" "-afi" "$fs_mountpoint"
	treew "$lwd/tree/tree -adfi p$fs_partnr $fs_uuid.txt" "-adfi" "$fs_mountpoint"
	treew "$lwd/tree/tree -aJ p$fs_partnr $fs_uuid.json" "-aJ" "$fs_mountpoint"
	treew "$lwd/tree/tree -apugsDJ --inodes --device p$fs_partnr $fs_uuid.json" -"apugsDJ --inodes --device" "$fs_mountpoint"
	cd "$fs_mountpoint"
	treew "$lwd/tree/tree -aH p$fs_partnr $fs_uuid.htm" "-aH" "$fs_mountpoint"
	cd "$cwd"
done

echo "${fna[@]}" | bat
for val in "${fna[@]}"; do sed -i "s/$disk/sdx/g" "$val" ; done
rm "$lwd/"*.tmp

#sudo smartctl -l error /dev/sdb
#sudo smartctl -l selftest /dev/sdb
#sudo smartctl -l devstat /dev/sdc
