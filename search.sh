#!/bin/bash

nflag=
lflag=
while getopts nl: name
do
    case $name in
    n)    nflag="n";;
    l)    lflag="less";;
          #lval="$OPTARG";;
    ?)    printf "Usage: %s: [-a] [-b value] args\n" $0
          exit 2;;
    esac
done
if [ ! -z "$nflag" ]; then
    printf "Option -n specified\n"
fi
if [ ! -z "$lflag" ]; then
    printf 'Option -l "%s" specified\n' "$lval"
fi
shift $(($OPTIND - 1))
printf "Remaining arguments are: %s\n" "$*"

if [ "$1" != "" ]; then
    text=$1
else
    read -p 'search text: ' text
fi

grep --color=auto -iH "$text" ./by-dt/c*/"tree -afi"* |
sed "s=/media/searinox= =" |
sed "s=\./by-dt/==" |
sed "s=/tree==" |
cut -c 2- |
awk '{$2=$4=""; print $0}' |
awk '{$1=$1$2; $2=""; print $0}' |
awk -v OFS=' ' '{$1=$1}1' |
grep --color=auto -i$nflag "$text" #2>&1 | tee "search_last.txt"

if [ ! -z "$lflag" ]; then
    less "search_last.txt"
fi

#| $lflag #| less -r
