#!/usr/bin/env bash
#
# Runs the configure command of the official nginx for Windows build
# (nginx/misc/GNUmakefile, target "win32"), plus the headers-more module.
#
# Must be started from a shell where vcvarsall.bat has already been run,
# so that cl.exe is on PATH.
#
# Env: OBJS, OPENSSL, ZLIB, PCRE - as defined in misc/GNUmakefile

set -euo pipefail

cd "$(dirname "$0")/../nginx"

# Join the recipe of the "win32" target into one command line.
cmd=$(sed -n '/^win32:/,/^$/p' misc/GNUmakefile \
      | sed -e '1d' -e 's/\\$//' | tr '\t\n' '  ')

cmd=${cmd//'$(CC)'/cl}
for v in OBJS OPENSSL ZLIB PCRE; do
    cmd=${cmd//"\$($v)"/${!v}}
done

if [[ $cmd == *'$('* ]]; then
    echo "::error::unknown make variable in win32 target: $cmd"
    exit 1
fi

cmd="$cmd --add-module=../headers-more"
echo "$cmd"
eval "$cmd"
