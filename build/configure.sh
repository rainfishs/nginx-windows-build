#!/usr/bin/env bash
#
# Runs nginx's auto/configure with the same options as the official
# nginx for Windows build (nginx/misc/GNUmakefile, target "win32"),
# plus the headers-more module.
#
# Must be started from a shell where vcvarsall.bat has already been run,
# so that cl.exe is on PATH.
#
# Env: OPENSSL, ZLIB, PCRE - source directory names under objs.msvc8/lib

set -euo pipefail

cd "$(dirname "$0")/../nginx"

OBJS=objs.msvc8

# Copied from misc/GNUmakefile (target "win32") of nginx 1.30.5;
# identical in 1.31.6.
args=(
    --with-cc=cl
    --builddir=$OBJS
    --with-debug
    --prefix=
    --conf-path=conf/nginx.conf
    --pid-path=logs/nginx.pid
    --http-log-path=logs/access.log
    --error-log-path=logs/error.log
    --sbin-path=nginx.exe
    --http-client-body-temp-path=temp/client_body_temp
    --http-proxy-temp-path=temp/proxy_temp
    --http-fastcgi-temp-path=temp/fastcgi_temp
    --http-scgi-temp-path=temp/scgi_temp
    --http-uwsgi-temp-path=temp/uwsgi_temp
    --with-cc-opt=-DFD_SETSIZE=1024
    --with-pcre=$OBJS/lib/$PCRE
    --with-zlib=$OBJS/lib/$ZLIB
    --with-http_v2_module
    --with-http_realip_module
    --with-http_addition_module
    --with-http_sub_module
    --with-http_dav_module
    --with-http_stub_status_module
    --with-http_flv_module
    --with-http_mp4_module
    --with-http_gunzip_module
    --with-http_gzip_static_module
    --with-http_auth_request_module
    --with-http_random_index_module
    --with-http_secure_link_module
    --with-http_slice_module
    --with-mail
    --with-stream
    --with-stream_realip_module
    --with-stream_ssl_preread_module
    --with-openssl=$OBJS/lib/$OPENSSL
    "--with-openssl-opt=no-asm no-tests no-makedepend -D_WIN32_WINNT=0x0501"
    --with-http_ssl_module
    --with-mail_ssl_module
    --with-stream_ssl_module
)


# Fail if the pinned library versions differ from the official build
# of the checked out nginx version.

for v in OPENSSL ZLIB PCRE; do
    official=$(sed -nE "s/^$v[[:space:]]*=//p" misc/GNUmakefile | tr -d '[:space:]')

    if [ "$official" != "${!v}" ]; then
        echo "::error::$v: official build uses '$official', workflow pins '${!v}'"
        exit 1
    fi
done


# Fail if the configure options differ from the official build.

official=$(sed -n '/^win32:/,/^$/p' misc/GNUmakefile \
           | grep -oE -- '--[a-z0-9_-]+' | sort -u)
ours=$(printf '%s\n' "${args[@]}" | grep -oE -- '^--[a-z0-9_-]+' | sort -u)

if [ "$official" != "$ours" ]; then
    echo "::error::configure options differ from misc/GNUmakefile (win32)"
    diff <(echo "$official") <(echo "$ours") || true
    exit 1
fi


./auto/configure "${args[@]}" --add-module=../headers-more
