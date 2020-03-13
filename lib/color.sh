#!/bin/bash
#
# Akk Color Funcs -- by Searinox

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
		white	| w)	color='37' ;;
		*) clr_usage ;;
	esac
	if [[ -z $2 ]] ; then
		IFS= ; while read -r line; do [[ $pflag -ne 1 ]] && echo -e '\e['"$color"'m'"$line"'\e[0m' || printf '\033[%sm%s\033[0m\n' "$color" "$line" ; done
	else
		[[ $pflag -ne 1 ]] && echo -e '\e['"$color"'m'"$2"'\e[0m' || printf '\033[%sm%s\033[0m\n' "$color" "$2"
	fi
}
