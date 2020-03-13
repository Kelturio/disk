#!/bin/bash
#
# Akk Disk Indexer Script -- by Searinox

clear && clear
SRC="$(readlink ${BASH_SOURCE[0]})"
DIR=${SRC%/*}; BASE=${SRC##*/}; FILE=${BASE%.*}; FILE=${FILE:=$BASE}; EXT=${BASE#$FILE}
. "${DIR}/${FILE}_parsing${EXT}" || { echo "Need argbash parsing script" >&2; exit 2; }

. "${DIR}/lib/color.sh"

printf 'Value of --%s: %s\n' 'option' "$_arg_option"
printf "'%s' is %s\\n" 'faketty' "$_arg_faketty"
printf "Value of '%s': %s\\n" 'disk' "$_arg_disk"
printf "Value of '%s': %s\\n" 'dt' "$_arg_dt"

#set -ueo pipefail

exec 3<> foo # open fd 3.

normalcol="$(tput sgr0)"


#trap 'echo -n "$normalcol" ; echo "$1 ; ' DEBUG
#set -x

# Red STDERR
# rse <command string>
rsexxx() {
    # We need to wrap each phrase of the command in quotes to preserve arguments that contain whitespace
    # Execute the command, swap STDOUT and STDERR, colour STDOUT, swap back
    ( (eval $(for phrase in "$@"; do echo -n "'$phrase' "; done) ) 3>&1 1>&2 2>&3 | sed -e "s/^\(.*\)$/$(echo -en \\033)[31;1m\1$(echo -en \\033)[0m/") 3>&1 1>&2 2>&3
}
#rse()(set -o pipefail;"$@" 2>&1>&3|sed $'s,.*,\e[31m&\e[m,'>&2)3>&1
#rse() { "$@" 2> >(sed $'s,.*,\e[36m&\e[m,'>&3) ; } 3>&2
#rse() { "$@" 3>&1 1>&2 2>&3 ; }
#rse() { "$@" 2>&3 ; } 3>&2
rse() { "$@" 1> >(clr p 1>&1) 2> >(clr r 1>&2) ; } 




#echo a >&3 # write to it


#rm {1,2,3,4}.txt;rm foo

#akk() { echo "akk" 1>&2 ; }
#akk12() { akk 2>&3 ; }

clr y "Akk Disk Indexer Script\n"

COLUMNS="$(tput cols)" ; LINES="$(tput lines)" ; echo "$COLUMNS x $LINES"

printf "%0$(tput cols)d" 0|tr '0' '='

echo $SHELLOPTS

cnf=": command not found"
if which "doas" > /dev/null ; then clr c "doas: found" ; sudo() { doas -- "$@" ; } ; else clr y "doas$cnf" ; fi

shopt -s expand_aliases #; source ~/.bash_aliases
calias() { if which "$2" ; then clr c "$2: found" ; alias "$1"="${3:-$1}" ; else clr y "$1$cnf" ; alias "$1"="${4:-$1}" ; fi ; alias "$1" | clr y ; }
#calias "bat" "bat" "bat --color always --paging never" "cat"
#calias "bat" "bat" "bat --paging never --wrap never" "cat"
calias "bat" "bat" "bat --paging never" "cat"
#calias "tree" "tree" "tree -C"

if which "ssh-askpass" ; then clr c "ssh-askpass: found" ; export SUDO_ASKPASS=$(which "ssh-askpass") ; else clr y "ssh-askpass$cnf" ; fi
sudo echo "\$SUDO_ASKPASS = $SUDO_ASKPASS" | clr c

[[ "$(id -u)" == "0" ]] && { clr red "Cannot run as root user" ; exit 1 ; }

#[[ -d "$HOME/Git/disk" ]] && cd "$HOME/Git/disk" || exit

pause () { clr y "pause" ; } #pause () { read -rp 'Press [Enter] key to continue...' ; }

treew() { echo "treew: $1 $2 $3" ; echo -e "$(tput sgr0)" ; sudo tree -o "$1" $2 "$3" ; }

own () { if [[ -O "$1" ]] ; then clr c "$FUNCNAME: already owned '$1'" ; else sudo chown "$USER":"$USER" "$1" && clr y "own: chowned '$1'" ; fi ; }

treeown () { for file in "$lwd/tree/tree -a"*.{txt,json,htm} ; do [[ -f $file ]] && own "$file" ; done ; }

hwi () { log="$lwd/hwinfo --$1 p$pn $uuid.txt" ; out=$(hwinfo --$1 --only /dev/$kname) ; [[ -z "$out" ]] && : || { echo "$out" > "$log" ; bat "$log" ; lfa+=("$log") ; } ; }

fgrep () { grep -Ef "$lwd/gsp.tmp" ; }

fawk () { awk '{print $9" "$10" "$11}' | seddev ; }

pipe () {
	log="$lwd/${1/<*/}.txt" ; cmd="${1/*</}"
	clr yellow "\n$cmd $2 ${3:+| $3} ${4:+| $4} ${5:+| $5} ${6:+| $6}"
	sudo $cmd $2 | ${3:-tee} | ${4:-tee} | ${5:-tee} | ${6:-tee} > "$log"
	bat "$log" ; lfa+=("$log")
}

faketty() { 0</dev/null script --quiet --flush --return --command "$(printf "%q " "$@")" /dev/null ; }

seddev () { sed 's=../../=/dev/=' ; }

seddisk () { sed 's=/dev/disk/by-=0 0 0 0 0 0 0 0 /dev/disk/by-=' ; }

sedracs() { sed 's/\x1b\[[0-9;]*m//g' ; }

sed::idx() { sed 's/ID-[[:digit:]][[:digit:]]*/ID-X/' ; }

[[ $_arg_disk != "" ]] && disk=$_arg_disk || read -rp 'dev disk: ' disk
[[ $_arg_dt != "" ]] && dt=$_arg_dt || read -rp 'dev tag: ' dt

dd="/dev/$disk"
id=$(stat -c%N /dev/disk/by-id/* | seddev | grep "$dd'" | head -n +1 | awk '{print $1}') ; id=${id##*/} ; id=${id%\'}
cwd=$(pwd) ; lwd="$cwd/by-dt/$dt" ; iwd="$cwd/by-id/$id"
cols="KNAME,MOUNTPOINT,UUID,FSTYPE,SIZE,MIN-IO,PHY-SEC,LOG-SEC,ROTA,TYPE,WWN,TRAN,LABEL,MODEL,SERIAL"
declare -a lfa

rse echo -e "\$disk\t= $disk\n\$dt \t= $dt\n\$dd \t= $dd\n\$id \t= $id\n\$cwd\t= $cwd\n\$lwd\t= $lwd\n\$iwd\t= $iwd\n" | bat ; pause

[[ -d "$lwd/tree" ]] || mkdir -pv "$lwd/tree" 2>&1 | bat
[[ ! -L "$iwd" ]] && ln -rs "$lwd" "$iwd" 2>&1 | bat

rse rm -v "$lwd/tree -a"*.txt "$lwd/tree -a"*.json "$lwd/tree -a"*.htm | bat
rse treeown | bat 
rse rm -v "$lwd/tree/tree -a"*.{txt,json,htm} | bat 

log="$lwd/gsp.tmp" ; output_list=("o KNAME" "po KNAME" "o NAME" "po NAME")
gsp=$( ( for args in "${output_list[@]}" ; do lsblk -ln -$args "$dd" ; done ) | sort -u )
gsp+=$( printf "\nFilesystem.*Size.*Use.*Mounted on\n" ; 
		printf "Drives:\nPartition:\nUnmounted:\n" ; 
		printf "/dev/disk/by-(id|label|partuuid|path|uuid):\n" )
echo "$gsp" | sed '/^$/d' > "$log" ; bat "$log"
gspd=$(head -n -5 "$log") ; echo "$gspd" | tee "$lwd/gspd.tmp" | bat

tree /dev/disk > "$lwd/$dt.id.txt" ; bat "$lwd/$dt.id.txt"

pipe "$dt.id<ls -alFR" "/dev/disk" fgrep seddisk fawk "sed 1i$dt" ; pause
pipe "stat -c%N" "/dev/disk/*/*" fgrep seddev
inxi_rgx='((?=.*ID-\d).*(sdb|dm).*(.|\n)+?((?=.*(Par|Unm)[a-z]+:)|(?=.*ID-\d|$))|.*(Dri|Par|Unm)[a-z]+:.*\n)'
#pipe "inxi -Dopluxxx" "--indent-min 800" "grep -f $lwd/gsp.tmp -A 1" ; pause
pipe "inxi -Dopluxxx" "-c 6 --indent-min 800 --width 80" "grep -Pzo $inxi_rgx" "tr -d '\0'" sedracs sed::idx ; pause
#log="$lwd/inxi -Dopluxxx.txt" ; inxitxt=$(cat "$log")
#(grep -n -f "$lwd/gsp.tmp" <<< "$inxitxt" ; grep -nA 1 -f "$lwd/gspd.tmp" <<< "$inxitxt") | 
#	sort -nu | sed 's/:/: /' | awk '$1="";1' | sedidx | sed '/^$/d' > "$log" ; bat "$log"

#inxi -Dopluxxxc 6 --indent-min 801 | cat | grep -Pzo "$inxi_rgx"; echo

pipe "lsblk -lo" "$cols $dd"
pipe "df -hP" "" fgrep
pipe "mount -l" "" fgrep ; pause
pipe "hdparm -I" "$dd"
pipe "smartctl -a" "$dd"
pipe "smartctl -x" "$dd"
pipe "smartctl -P show" "$dd"
#: '
while read -r line ; do
#sed '1d' "$lwd/lsblk -lo.txt" | while read -r line ; do
	rse alias "sudo"
	rse alias "sudo" | bat
	rse alias "sudo" 2>&1 | bat
	kname=$(awk '{print $1}' <<< "$line")
	echo "\$kname = $kname"
	mountpoint=$(lsblk -no MOUNTPOINT /dev/$kname | head -n 1)
	uuid=$(lsblk -no UUID /dev/$kname | head -n 1)
	pn=$(sed "s/$disk//" <<< "$kname")	
	if [[ $(cut -c1-3 <<< "$kname") == "dm-" ]]; then
		name=$(lsblk -no NAME /dev/$kname | head -n 1)
		puuid=$(sed "s/luks-//" <<< "$name")
		pn="$(blkid --uuid "$puuid" | sed "s=$dd==")c"
	fi
	echo -e "\$kname\t\t= $kname\n\$mountpoint\t= $mountpoint\n\$uuid\t\t= $uuid\n\$pn \t\t= $pn\n\$name\t\t= $name\n\$puuid\t\t= $puuid\n" | bat
	hwi "disk" ; hwi "partition"
	[[ -z "$mountpoint" ]] && continue
	rse treew "$lwd/tree/tree -a p$pn $uuid.txt" "-a" "$mountpoint"
	treew "$lwd/tree/tree -afi p$pn $uuid.txt" "-afi" "$mountpoint"
	treew "$lwd/tree/tree -adfi p$pn $uuid.txt" "-adfi" "$mountpoint"
	treew "$lwd/tree/tree -aJ p$pn $uuid.json" "-aJ" "$mountpoint"
	treew "$lwd/tree/tree -apugsDJ --inodes --device p$pn $uuid.json" "-apugsDJ --inodes --device" "$mountpoint"
	cd "$mountpoint"
	treew "$lwd/tree/tree -aH p$pn $uuid.htm" "-aH" "$mountpoint"
	cd "$OLDPWD"
done < <(sed '1d' "$lwd/lsblk -lo.txt")
#'
treeown | bat
#sleep 1
{ for lf in "${lfa[@]}"; do echo "$lf" ; 
	sed -i -e "s/$disk/sdx/" "$lf" -e "s/dm-[[:digit:]][[:digit:]]*/dm-x/" "$lf" ; done } | bat

#rm -f "$lwd/"*.tmp

exec 3>&- # close fd 3.

clr c "\nDONE"

[[ $BASH_SOURCE != "$0" ]] || main "$@"
