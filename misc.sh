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
