#!/bin/bash

wd=$(pwd)
head -qn 2 ./by-dt/*/*".id.txt" | sed -n 'p;n' | tee 1.tmp
head -qn 2 ./by-dt/*/*".id.txt" | sed -n 'n;p' | tee 2.tmp
paste 1.tmp 2.tmp | while read -r line ; do
	dt=$(awk '{print $1}' <<< "$line")
	id=$(awk '{print $2}' <<< "$line")
	echo "$dt $id"
	dir="$wd/by-id/$id"
	[ ! -L "$dir" ] && ln -rs "$wd/by-dt/$dt" "$dir"
done
rm 1.tmp 2.tmp
