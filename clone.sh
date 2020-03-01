#!/bin/bash

# ntfsclone --save-image -o - /dev/sdXX | ntfsclone2vhd - /mnt/usb/output.vhd
sudo ntfsclone --save-image -o - /dev/sdb1 | sudo ntfsclone2vhd - /media/searinox/VM1/ata-WDC_WD7500BPVT-60HXZT3_WD-WX21E43CAH33/B8B280D9B2809E0E.vhd
sudo ntfsclone --save-image -o - /dev/sdb2 | sudo ntfsclone2vhd - /media/searinox/VM1/ata-WDC_WD7500BPVT-60HXZT3_WD-WX21E43CAH33/C6B06CE4B06CDC85.vhd
sudo ntfsclone --save-image -o - /dev/sdb3 | sudo ntfsclone2vhd - /media/searinox/VM1/ata-WDC_WD7500BPVT-60HXZT3_WD-WX21E43CAH33/486A95336A951EAE.vhd
