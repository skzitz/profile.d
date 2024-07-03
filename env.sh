#!/usr/bin/bash

trap CLEANUP exit return
__ret_val=0
__filename="$(basename ${BASH_SOURCE[0]})"

# Generate debug output if the passed level (arg1) is >0 global $debug_level
DEBUG() {
  [ -z "${debug_level}" ] && return 0;
  [ "${debug_level}" -lt "$1" ] && return 0;
  shift
  echo -n "${__filename}:" >&2
  echo "$@" >&2
}

# Generate verbose output if the passed level (arg1) is >0 global $debug_level
VERBOSE() {
  [ -z "${verbose_level}" ] && return 0;
  [ "${verbose_level}" -lt "$1" ] && return 0;
  shift
  echo -n "${__filename}:"
  echo "$@"
}


CLEANUP() {
    unset debug_level vervose_level xdg_config_home config_home profile_d files
    unset __ret_val __filename
}


usage() {
    cat <<-_EOF_
$__filename [-h] [-v] [-d] [--verbose[=verbose_level]] [--debug[=debug_level]]"
  Checks and executes various 'setup' scripts so we can split out bashrc/profile"

_EOF_

}

# use DEBUG_LEVEL preferentially, fall  back to XDG_DEBUG_LEVEL if its set.
debug_level="${DEBUG_LEVEL:-$XDG_DEBUG_LEVEL}"
[ -z "${debug_level}" ] && unset debug_level

DEBUG 0 "Starting.  Debug level=${debug_level}"
DEBUG 1 "\$DEBUG_LEVEL=[${DEBUG_LEVEL}]"
DEBUG 1 "\$XDG_DEBUG_LEVEL=[${XDG_DEBUG_LEVEL}]"

# use CONFIG_HOME preferentially, fall back to XDG_CONFIG_HOME
# give a reasonable default if xdg isn't setup
xdg_config_home=${XDG_CONFIG_HOME:-${HOME}/.config}
config_home=${CONFIG_HOME:-$xdg_config_home}
profile_d=${PROFILE_D:-"$config_home/profile.d"}

DEBUG 2 "config_home=${config_home}"
DEBUG 2 "profile_d=${profile_d}"

# iterate over each file in $PROFILE_D and source it

# some simple sanity checks
if [ ! -d "${profile_d}" ]; then
    echo "Calculated profile direcory = \"${profile_d}\" but it is not a directory" >& 2
    return 1
fi
if [ ! -r "${profile_d}" ]; then
    echo "Calculated profile directory = \"${profile_d}\", but is not readable" >& 2
    return 2
fi

# find files of form S${NAME} ... we explicity ignore backup files (ending in ~)
files=$(run-parts --test --regex '^S.*[^~]$' "${profile_d}")

for file in $files; do
    echo "file=${file}"
done

usage

# this odd construct allows us to return an exit value whether we
# execute this script (needing an 'exit' ) or sourced it (needing a
# 'return').
# shellcheck disable=SC2317
return "$__ret_val" 2>/dev/null || exit "$__ret_val"
