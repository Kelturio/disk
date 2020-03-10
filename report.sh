#!/bin/bash

# Akk Disk Indexer Script -- by Searinox

#set -eu

_red()    { IFS= ; while read -r line; do echo -e '\e[31m'$line'\e[0m'; done; }

clr_usage() { echo -e 'usage:\n  some-command | colorize {black, red, green, yellow, blue, purple, cyan, white}' >&2 ; exit 1 ; }

clr() {
	eflag= ; pflag=
	while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
		-p | --printf ) pflag=1 ;;
		*) clr_usage ;;
	esac; shift; done
	if [[ "$1" == '--' ]]; then shift; fi
	[[ -z $1 ]] && clr_usage
	case $1 in
		black)  color='30' ;;
		red)    color='31' ;;
		green)  color='32' ;;
		yellow | y) color='33' ;;
		blue)   color='34' ;;
		purple) color='35' ;;
		cyan | c)   color='36' ;;
		white)  color='36' ;;
		*) clr_usage ;;
	esac
	if [[ -z $2 ]] ; then
		IFS= ; while read -r line; do [[ $pflag -ne 1 ]] && echo -e '\e['"$color"'m'"$line"'\e[0m' || printf '\033[%sm%s\033[0m\n' "$color" "$line" ; done
	else
		[[ $pflag -ne 1 ]] && echo -e '\e['"$color"'m'"$2"'\e[0m' || printf '\033[%sm%s\033[0m\n' "$color" "$2"
	fi
}

clr y "Akk Disk Indexer Script\n"

shopt -s expand_aliases #; source ~/.bash_aliases

cnf=": command not found"
calias() { if which "$2" ; clr c "$2: found" ; then alias "$1"="${3:-$1}" ; else clr y "$1$cnf" ; alias "$1"="${4:-$1}" ; fi ; alias "$1" | clr y ; }
calias "bat" "bat" "bat --paging never" "cat"
calias "sudo" "doas" "$(which doas) --"
#alias tree="tree -C"

if which "ssh-askpass" ; then clr y "ssh-askpass: found" ; export SUDO_ASKPASS=$(which "ssh-askpass") ; else clr y "ssh-askpass$cnf" ; fi
sudo clr y "\$SUDO_ASKPASS = $SUDO_ASKPASS" | bat

[[ "$(id -u)" == "0" ]] && { clr red "Cannot run as root user" ; exit 1 ; }

[[ -d "$HOME/Git/disk" ]] && cd "$HOME/Git/disk" || exit

# This is all the interface you need.
# Remember, that this burns FD=3!
_passback() { while [[ 1 -lt $# ]]; do printf '%q=%q;' "$1" "${!1}"; shift; done; return $1; }
passback() { _passback "$@" "$?"; }
_capture() { { out="$("${@:2}" 3<&-; "$2_" >&3)"; ret=$?; printf "%q=%q;" "$1" "$out"; } 3>&1; echo "(exit $ret)"; }
capture() { eval "$(_capture "$@")"; }

pause () { clr y "pause" ; } #pause () { read -rp 'Press [Enter] key to continue...' ; }

treew() { sudo tree -o "$1" "$2" "$3" ; }

own () { [[ -O "$1" ]] && : || { sudo chown "$USER":"$USER" "$1" && echo -e "chowned\t$1" ; } ; }

treeown () { for file in "$lwd/tree/tree -a"*.{txt,json,htm} ; do own "$file" ; done ; }

hwi () { log="$lwd/hwinfo --$1 p$pn $uuid.txt" ; out=$(hwinfo --$1 --only /dev/$kname) ; [[ -z "$out" ]] && : || { echo "$out" > "$log" ; bat "$log" ; } ; }

fgrep () { grep -f "$lwd/gsp.tmp" ; }

fawk () { awk '{print $9" "$10" "$11}' | seddev ; }

pipe () {
	log="$lwd/${1/<*/}.txt" ; cmd="${1/*</}"
	clr yellow "\n$cmd $2 ${3:+| $3} ${4:+| $4} ${5:+| $5}"
	sudo $cmd $2 | ${3:-tee} | ${4:-tee} | ${5:-tee} > "$log"
	bat "$log" ; lfa+=("$log")
}

faketty() { 0</dev/null script --quiet --flush --return --command "$(printf "%q " "$@")" /dev/null ; }

seddev () { sed 's=../../=/dev/=' ; }

[[ $1 != "" ]] && disk=$1 || read -rp 'dev disk: ' disk
[[ $2 != "" ]] && dt=$2 || read -rp 'dev tag: ' dt

dd="/dev/$disk" ; clr y "\$dd = $dd"
id=$(stat -c%N /dev/disk/by-id/* | seddev | grep "$dd'" | head -n +1 | awk '{print $1}') ; id=${id##*/} ; idx=${id%\'}
cwd=$(pwd) ; lwd="$cwd/by-dt/$dt" ; iwd="$cwd/by-id/$id"
cols="KNAME,MOUNTPOINT,UUID,FSTYPE,SIZE,MIN-IO,PHY-SEC,LOG-SEC,ROTA,TYPE,WWN,TRAN,LABEL,MODEL,SERIAL"
declare -a lfa

clr y "\$disk\t= $disk\n\$dt \t= $dt\n\$id \t= $id\n\$cwd\t= $cwd\n\$lwd\t= $lwd\n\$iwd\t= $iwd\n" | bat ; pause

[[ -d "$lwd/tree" ]] || mkdir -pv "$lwd/tree" 2>&1 | bat
[[ ! -L "$iwd" ]] && ln -rs "$lwd" "$iwd" 2>&1 | bat

rm -f "$lwd/tree -a"*.txt "$lwd/tree -a"*.json "$lwd/tree -a"*.htm 2>&1 | bat
treeown | bat && rm "$lwd/tree/tree -a"*.{txt,json,htm} 2>&1 | bat 

log="$lwd/gsp.tmp" ; output_list=("o KNAME" "po KNAME" "o NAME" "po NAME")
gsp=$( (for args in "${output_list[@]}" ; do lsblk -ln -$args "$dd" ; done) | sort -u)
gsp+=$(printf "\nFilesystem.*Size.*Use.*Mounted on\n" ; printf "Drives:\nPartition:\nUnmounted:\n")
echo "$gsp" | sed '/^$/d' > "$log" ; bat "$log"
gspd=$(head -n -4 "$log") ; echo "$gspd" | tee "$lwd/gspd.tmp" | bat

tree /dev/disk > "$lwd/$dt.id.txt" ; bat "$lwd/$dt.id.txt"

pipe "$dt.id<ls -alFR" "/dev/disk" fgrep fawk "sed 1i$dt" ; pause
pipe "stat -c%N" "/dev/disk/*/*" fgrep seddev

pipe "inxi -Dopluxxx" "--indent-min 800" "grep -f $lwd/gsp.tmp -A 1" ; pause
log="$lwd/inxi -Dopluxxx.txt" ; inxitxt=$(cat "$log")
(grep -n -f "$lwd/gsp.tmp" <<< "$inxitxt" ; grep -nA 1 -f "$lwd/gspd.tmp" <<< "$inxitxt") | 
	sort -nu | sed 's/:/: /' | awk '$1="";1' | sed '/^$/d' > "$log" ; bat "$log"

pipe "lsblk -lo" "$cols $dd"
pipe "df -hP" "" fgrep
pipe "mount -l" "" fgrep ; pause
pipe "hdparm -I" "$dd"
pipe "smartctl -a" "$dd"
pipe "smartctl -x" "$dd"
pipe "smartctl -P show" "$dd"
: '
sed '1d' "$lwd/lsblk -lo.txt" | while read -r line ; do
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
	treew "$lwd/tree/tree -a p$pn $uuid.txt" "-a" "$mountpoint"
	treew "$lwd/tree/tree -afi p$pn $uuid.txt" "-afi" "$mountpoint"
	treew "$lwd/tree/tree -adfi p$pn $uuid.txt" "-adfi" "$mountpoint"
	treew "$lwd/tree/tree -aJ p$pn $uuid.json" "-aJ" "$mountpoint"
	treew "$lwd/tree/tree -apugsDJ --inodes --device p$pn $uuid.json" -"apugsDJ --inodes --device" "$mountpoint"
	cd "$mountpoint"
	treew "$lwd/tree/tree -aH p$pn $uuid.htm" "-aH" "$mountpoint"
	cd "$cwd"
	treeown | bat
done
'
sleep 1
{ for lf in "${lfa[@]}"; do echo "$lf" ; sed -i "s/$disk/sdx/g" "$lf" ; done } | bat

#rm -f "$lwd/"*.tmp

clr yellow "\nDONE"
