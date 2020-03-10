#!/bin/bash

# Akk Disk Indexer Script -- by Searinox

#set -eu

clr_usage() { echo -e 'usage:\n  some-cmd | clr -p {black, red, green, yellow, blue, purple, cyan, white}\n  clr $color $text ' >&2 ; exit 1 ; }

clr() {
	pflag=
	while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
		-p | --printf ) pflag=1 ;;
		*) clr_usage ;;
	esac; shift; done
	if [[ "$1" == '--' ]]; then shift; fi
	[[ -z $1 ]] && clr_usage
	case $1 in
		black	| b)	color='30' ;;
		red		| r)	color='31' ;;
		green	| g)	color='32' ;;
		yellow	| y)	color='33' ;;
		blue	| be)	color='34' ;;
		purple	| p)	color='35' ;;
		cyan	| c)	color='36' ;;
		white	| w)	color='36' ;;
		*) clr_usage ;;
	esac
	if [[ -z $2 ]] ; then
		IFS= ; while read -r line; do [[ $pflag -ne 1 ]] && echo -e '\e['"$color"'m'"$line"'\e[0m' || printf '\033[%sm%s\033[0m\n' "$color" "$line" ; done
	else
		[[ $pflag -ne 1 ]] && echo -e '\e['"$color"'m'"$2"'\e[0m' || printf '\033[%sm%s\033[0m\n' "$color" "$2"
	fi
}

# Red STDERR
# rse <command string>
function rse()
{
    # We need to wrap each phrase of the command in quotes to preserve arguments that contain whitespace
    # Execute the command, swap STDOUT and STDERR, colour STDOUT, swap back
    ((eval $(for phrase in "$@"; do echo -n "'$phrase' "; done)) 3>&1 1>&2 2>&3 | sed -e "s/^\(.*\)$/$(echo -en \\033)[31;1m\1$(echo -en \\033)[0m/") 3>&1 1>&2 2>&3
}

clr y "Akk Disk Indexer Script\n"

shopt -s expand_aliases #; source ~/.bash_aliases

cnf=": command not found"
calias() { if which "$2" ; clr c "$2: found" ; then alias "$1"="${3:-$1}" ; else clr y "$1$cnf" ; alias "$1"="${4:-$1}" ; fi ; alias "$1" | clr y ; }
calias "bat" "bat" "bat --paging never" "cat"
calias "sudo" "doas" "$(which doas) --"
#calias "tree" "tree" "tree -C"

if which "ssh-askpass" ; then clr c "ssh-askpass: found" ; export SUDO_ASKPASS=$(which "ssh-askpass") ; else clr y "ssh-askpass$cnf" ; fi
sudo echo "\$SUDO_ASKPASS = $SUDO_ASKPASS" | clr c

[[ "$(id -u)" == "0" ]] && { clr red "Cannot run as root user" ; exit 1 ; }

[[ -d "$HOME/Git/disk" ]] && cd "$HOME/Git/disk" || exit

pause () { clr y "pause" ; } #pause () { read -rp 'Press [Enter] key to continue...' ; }

treew() { rse sudo tree -o "$1" $2 "$3" ; }

own () { if [[ -O "$1" ]] ; then clr c "own: already owned '$1'" ; else rse sudo chown "$USER":"$USER" "$1" && clr y "own: chowned '$1'" ; fi ; }

treeown () { for file in "$lwd/tree/tree -a"*.{txt,json,htm} ; do [[ -f $file ]] && own "$file" ; done ; }

hwi () { log="$lwd/hwinfo --$1 p$pn $uuid.txt" ; out=$(hwinfo --$1 --only /dev/$kname) ; [[ -z "$out" ]] && : || { echo "$out" > "$log" ; bat "$log" ; } ; }

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

[[ $1 != "" ]] && disk=$1 || read -rp 'dev disk: ' disk
[[ $2 != "" ]] && dt=$2 || read -rp 'dev tag: ' dt

dd="/dev/$disk"
id=$(stat -c%N /dev/disk/by-id/* | seddev | grep "$dd'" | head -n +1 | awk '{print $1}') ; id=${id##*/} ; id=${id%\'}
cwd=$(pwd) ; lwd="$cwd/by-dt/$dt" ; iwd="$cwd/by-id/$id"
cols="KNAME,MOUNTPOINT,UUID,FSTYPE,SIZE,MIN-IO,PHY-SEC,LOG-SEC,ROTA,TYPE,WWN,TRAN,LABEL,MODEL,SERIAL"
declare -a lfa

clr y "\$disk\t= $disk\n\$dt \t= $dt\n\$dd \t= $dd\n\$id \t= $id\n\$cwd\t= $cwd\n\$lwd\t= $lwd\n\$iwd\t= $iwd\n" | bat ; pause

[[ -d "$lwd/tree" ]] || mkdir -pv "$lwd/tree" 2>&1 | bat
[[ ! -L "$iwd" ]] && ln -rs "$lwd" "$iwd" 2>&1 | bat

rse rm -v "$lwd/tree -a"*.txt "$lwd/tree -a"*.json "$lwd/tree -a"*.htm 2>&1 | bat
rse treeown | bat 
rse rm -v "$lwd/tree/tree -a"*.{txt,json,htm} 2>&1 | bat 

log="$lwd/gsp.tmp" ; output_list=("o KNAME" "po KNAME" "o NAME" "po NAME")
gsp=$( ( for args in "${output_list[@]}" ; do lsblk -ln -$args "$dd" ; done ) | sort -u )
gsp+=$( printf "\nFilesystem.*Size.*Use.*Mounted on\n" ; 
		printf "Drives:\nPartition:\nUnmounted:\n" ; 
		printf "/dev/disk/by-(id|label|partuuid|path|uuid):\n" )
echo "$gsp" | sed '/^$/d' > "$log" ; bat "$log"
gspd=$(head -n -4 "$log") ; echo "$gspd" | tee "$lwd/gspd.tmp" | bat

tree /dev/disk > "$lwd/$dt.id.txt" ; bat "$lwd/$dt.id.txt"

pipe "$dt.id<ls -alFR" "/dev/disk" fgrep seddisk fawk "sed 1i$dt" ; pause
pipe "stat -c%N" "/dev/disk/*/*" fgrep seddev

pipe "inxi -Dopluxxx" "--indent-min 800" "grep -f $lwd/gsp.tmp -A 1" ; pause
log="$lwd/inxi -Dopluxxx.txt" ; inxitxt=$(cat "$log")
(grep -n -f "$lwd/gsp.tmp" <<< "$inxitxt" ; grep -nA 1 -f "$lwd/gspd.tmp" <<< "$inxitxt") | 
	sort -nu | sed 's/:/: /' | awk '$1="";1' | sed "s/ID-[[:digit:]][[:digit:]]*/ID-X/" | sed '/^$/d' > "$log" ; bat "$log"

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
	treew "$lwd/tree/tree -apugsDJ --inodes --device p$pn $uuid.json" "-apugsDJ --inodes --device" "$mountpoint"
	cd "$mountpoint"
	treew "$lwd/tree/tree -aH p$pn $uuid.htm" "-aH" "$mountpoint"
	cd "$cwd"
	rse treeown | bat
done
'
sleep 1
{ for lf in "${lfa[@]}"; do echo "$lf" ; sed -i "s/$disk/sdx/" "$lf" ; done } | bat
{ for lf in "${lfa[@]}"; do echo "$lf" ; sed -i "s/dm-[[:digit:]][[:digit:]]*/dm-x/" "$lf" ; done } | bat

#rm -f "$lwd/"*.tmp

clr yellow "\nDONE"
