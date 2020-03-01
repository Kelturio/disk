#!/bin/bash

if [ "$1" != "" ]; then
    text=$1
else
    read -p 'search text: ' text
fi

grep --color=auto -iH "$text" ./by-dt/c*/"smartctl -a.txt"


# mount -t ntfs-3g /dev/sdb1 /mnt/ntfs/ 
# mount -t ntfs-3g /dev/sdb1 /mnt/wwn-0x5000cca8a8d11688-part1/
