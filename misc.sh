#!/bin/bash


# 
sudo smartctl -l error /dev/sdb
sudo smartctl -l selftest /dev/sdb
sudo smartctl -l devstat /dev/sdc


# dist upgrade
sudo -s <<< 'apt update -y && apt dist-upgrade -y'


# Check for less, install if needed:
dpkg -l | grep -qw less || sudo apt install -yyq less


# symlink src target in homedir
s="$HOME/Git/disk/report.sh";t="$HOME/bin/report.sh";echo "$s $t";[ ! -L "$t" ] && ln -s "$s" "$t" 2>&1 | bat


# Don't allow running as root
if [ "$(id -u)" == "0" ]; then
	show_message --error $"Cannot run as root user"
	exit 1
fi


#
hwinfo

# Install Rust - Rust Programming Language
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh


#copied from rustup-init.sh
say() {
    printf 'rustup: %s\n' "$1"
}

err() {
    say "$1" >&2
    exit 1
}

need_cmd() {
    if ! check_cmd "$1"; then
        err "need '$1' (command not found)"
    fi
}

check_cmd() {
    command -v "$1" > /dev/null 2>&1
}

assert_nz() {
    if [ -z "$1" ]; then err "assert_nz $2"; fi
}

# Run a command that should never fail. If the command fails execution
# will immediately terminate with an error showing the failing
# command.
ensure() {
    if ! "$@"; then err "command failed: $*"; fi
}

# This is just for indicating that commands' results are being
# intentionally ignored. Usually, because it's being executed
# as part of error handling.
ignore() {
    "$@"
}

# This wraps curl or wget. Try curl first, if not installed,
# use wget instead.
downloader() {
    local _dld
    if check_cmd curl; then
        _dld=curl
    elif check_cmd wget; then
        _dld=wget
    else
        _dld='curl or wget' # to be used in error message of need_cmd
    fi

    if [ "$1" = --check ]; then
        need_cmd "$_dld"
    elif [ "$_dld" = curl ]; then
        if ! check_help_for curl --proto --tlsv1.2; then
            echo "Warning: Not forcing TLS v1.2, this is potentially less secure"
            curl --silent --show-error --fail --location "$1" --output "$2"
        else
            curl --proto '=https' --tlsv1.2 --silent --show-error --fail --location "$1" --output "$2"
        fi
    elif [ "$_dld" = wget ]; then
        if ! check_help_for wget --https-only --secure-protocol; then
            echo "Warning: Not forcing TLS v1.2, this is potentially less secure"
            wget "$1" -O "$2"
        else
            wget --https-only --secure-protocol=TLSv1_2 "$1" -O "$2"
        fi
    else
        err "Unknown downloader"   # should not reach here
    fi
}


# File: /home/searinox/.cargo/env
export PATH="$HOME/.cargo/bin:$PATH"


script --flush --quiet --return /tmp/ansible-output.txt --command "my-ansible-command"
script --flush --quiet --return /tmp/ansible-output.txt --command "my-ansible-command" > /dev/null
#script -q /dev/null cargo build < /dev/null | less -R
#script -q /dev/null ls | cat
script --return --quiet -c "[executable string]" /dev/null
0<&- script -qfc "git status" /dev/null | less -R
faketty() {
    script -qfc "$(printf "%q " "$@")" /dev/null
}
function faketty { script -qfc "$(printf "%q " "$@")" /dev/null; }
faketty() {                       
    0</dev/null script --quiet --flush --return --command "$(printf "%q " "$@")" /dev/null
}

command 2> >(while read line; do echo -e "\e[01;31m$line\e[0m" >&2; done)
command 2> >(while read line; do echo -e "$(tput setaf 1)$line$(tput sgr0)" >&2; done)

command 2> >(sed $'s,.*,\e[31m&\e[m,'>&2)
color()(set -o pipefail;"$@" 2>&1>&3|sed $'s,.*,\e[31m&\e[m,'>&2)3>&1


# Red STDERR
# rse <command string>
function rse()
{
    # We need to wrap each phrase of the command in quotes to preserve arguments that contain whitespace
    # Execute the command, swap STDOUT and STDERR, colour STDOUT, swap back
    ((eval $(for phrase in "$@"; do echo -n "'$phrase' "; done)) 3>&1 1>&2 2>&3 | sed -e "s/^\(.*\)$/$(echo -en \\033)[31;1m\1$(echo -en \\033)[0m/") 3>&1 1>&2 2>&3
}
#You can add set -o pipefail; before (eval for redirect exit code – kvaps Jun 27 '19 at 14:34

#https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_codes

color() {
      printf '\033[%sm%s\033[m\n' "$@"
      # usage color "31;5" "string"
      # 0 default
      # 5 blink, 1 strong, 4 underlined
      # fg: 31 red,  32 green, 33 yellow, 34 blue, 35 purple, 36 cyan, 37 white
      # bg: 40 black, 41 red, 44 blue, 45 purple
      }
string="Hello world!"
color '31;1' "$string" >&2

make 2>&1 | sed -e 's/.*\bWARN.*/\x1b[7m&\x1b[0m/i' -e 's/.*\bERR.*/\x1b[93;41m&\x1b[0m/i'
flasher () { while true; do printf \\e[?5h; sleep 0.1; printf \\e[?5l; read -s -n1 -t1 && break; done; }
printf \\033c # This will reset the console, similar to the command reset on modern Linux systems

black()  { IFS= ; while read -r line; do echo -e '\e[30m'$line'\e[0m'; done; }
red()    { IFS= ; while read -r line; do echo -e '\e[31m'$line'\e[0m'; done; }
green()  { IFS= ; while read -r line; do echo -e '\e[32m'$line'\e[0m'; done; }
yellow() { IFS= ; while read -r line; do echo -e '\e[33m'$line'\e[0m'; done; }
blue()   { IFS= ; while read -r line; do echo -e '\e[34m'$line'\e[0m'; done; }
purple() { IFS= ; while read -r line; do echo -e '\e[35m'$line'\e[0m'; done; }
cyan()   { IFS= ; while read -r line; do echo -e '\e[36m'$line'\e[0m'; done; }
white()  { IFS= ; while read -r line; do echo -e '\e[37m'$line'\e[0m'; done; }
echo '    foo\n    bar' | red
yellow() { if [[ -z $1 ]] ; then IFS= ; while read -r line; do echo -e '\e[33m'$line'\e[0m' ; done ; else color "0;33;40" "$@" ; fi ; }

exec 9>&2
exec 8> >(
    while IFS='' read -r line || [ -n "$line" ]; do
       echo -e "\033[31m${line}\033[0m"
    done
)
function undirect(){ exec 2>&9; }
function redirect(){ exec 2>&8; }
trap "redirect;" DEBUG
PROMPT_COMMAND='undirect;'


dir=`cd "$dir"`

absolute_path() {
    cd "$(dirname "$1")"
    case $(basename $1) in
        ..) echo "$(dirname $(pwd))";;
        .)  echo "$(pwd)";;
        *)  echo "$(pwd)/$(basename $1)";;
    esac
}

alias realpath="perl -MCwd -e 'print Cwd::realpath(\$ARGV[0]),qq<\n>'"

stat -c%N /dev/disk/*/*


$ git clone https://github.com/bartobri/no-more-secrets.git
$ cd ./no-more-secrets
$ make nms
$ make sneakers             ## Optional
$ sudo make install


sudo apt install libpam0g-dev