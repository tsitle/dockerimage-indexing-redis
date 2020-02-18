#!/bin/bash

#
# by TS, Feb 2020
#

VAR_MYNAME="$(basename "$0")"

# ----------------------------------------------------------

# Outputs CPU architecture string
#
# @param string $1 debian_rootfs|debian_dist
#
# @return int EXITCODE
function _getCpuArch() {
	case "$(uname -m)" in
		x86_64*)
			echo -n "amd64"
			;;
		i686*)
			if [ "$1" = "qemu" ]; then
				echo -n "i386"
			elif [ "$1" = "s6_overlay" -o "$1" = "alpine_dist" ]; then
				echo -n "x86"
			else
				echo -n "i386"
			fi
			;;
		aarch64*)
			if [ "$1" = "debian_rootfs" ]; then
				echo -n "arm64v8"
			elif [ "$1" = "debian_dist" ]; then
				echo -n "arm64"
			else
				echo "$VAR_MYNAME: Error: invalid arg '$1'" >/dev/stderr
				return 1
			fi
			;;
		armv7*)
			if [ "$1" = "debian_rootfs" ]; then
				echo -n "arm32v7"
			elif [ "$1" = "debian_dist" ]; then
				echo -n "armhf"
			else
				echo "$VAR_MYNAME: Error: invalid arg '$1'" >/dev/stderr
				return 1
			fi
			;;
		*)
			echo "$VAR_MYNAME: Error: Unknown CPU architecture '$(uname -m)'" >/dev/stderr
			return 1
			;;
	esac
	return 0
}

_getCpuArch debian_dist >/dev/null || exit 1

# ----------------------------------------------------------

cd build-ctx || exit 1

# ----------------------------------------------------------

LVAR_REDIS_VERSION="5.0.7"

LVAR_IMAGE_NAME="indexing-redis-$(_getCpuArch debian_dist)"
LVAR_IMAGE_VER="$LVAR_REDIS_VERSION"
LVAR_IMAGE_VER_MAJMIN="$(echo -n "$LVAR_IMAGE_VERSION" | cut -f1-2 -d.)"

docker build \
		--build-arg CF_REDIS_VERSION="$LVAR_REDIS_VERSION" \
		-t "$LVAR_IMAGE_NAME":"$LVAR_IMAGE_VER" \
		. || exit 1

if [ "$LVAR_IMAGE_VERSION" != "$LVAR_IMAGE_VER_MAJMIN" ]; then
	docker image tag \
			"$LVAR_IMAGE_NAME":"$LVAR_IMAGE_VERSION" \
			"$LVAR_IMAGE_NAME":"$LVAR_IMAGE_VER_MAJMIN" || exit 1
fi

exit 0
