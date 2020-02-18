#!/bin/bash

#
# by TS, Feb 2020
#

VAR_MYNAME="$(basename "$0")"

# ----------------------------------------------------------------------

export HOST_IP=$(/sbin/ip route|awk '/default/ { print $3 }')
echo "$HOST_IP dockerhost" >> /etc/hosts

# ----------------------------------------------------------------------

CF_SYSUSR_RED_USER_ID=${CF_SYSUSR_RED_USER_ID:-999}
CF_SYSUSR_RED_GROUP_ID=${CF_SYSUSR_RED_GROUP_ID:-999}

# ----------------------------------------------------------

function _sleepBeforeAbort() {
	# to allow the user to see this message in 'docker logs -f CONTAINER' we wait before exiting
	echo "$VAR_MYNAME: (sleeping 5s before aborting)" >/dev/stderr
	local TMP_CNT=0
	while [ $TMP_CNT -lt 5 ]; do
		sleep 1
		echo "$VAR_MYNAME: (...)" >/dev/stderr
		TMP_CNT=$(( TMP_CNT + 1 ))
	done
	echo "$VAR_MYNAME: (aborting now)" >/dev/stderr
	exit 1
}

# ----------------------------------------------------------

# @param string $1 Username/Groupname
#
# @return void
function _removeUserAndGroup() {
	getent passwd "$1" >/dev/null 2>&1 && userdel -f "$1"
	getent group "$1" >/dev/null 2>&1 && groupdel "$1"
}

# Change numeric IDs of user/group to user-supplied values
#
# @param string $1 Username/Groupname
# @param string $2 Numeric ID for User as string
# @param string $3 Numeric ID for Group as string
# @param string $4 optional: Additional Group-Memberships for User
#
# @return int EXITCODE
function _createUserGroup() {
	local TMP_NID_U="$2"
	local TMP_NID_G="$3"
	echo -n "$TMP_NID_U" | grep -q -E "^[0-9]*$" || {
		echo "$VAR_MYNAME: Error: non-numeric User ID '$TMP_NID_U' supplied for '$1'. Aborting." >/dev/stderr
		return 1
	}
	echo -n "$TMP_NID_G" | grep -q -E "^[0-9]*$" || {
		echo "$VAR_MYNAME: Error: non-numeric Group ID '$TMP_NID_G' supplied '$1'. Aborting." >/dev/stderr
		return 1
	}
	[ ${#TMP_NID_U} -gt 5 ] && {
		echo "$VAR_MYNAME: Error: numeric User ID '$TMP_NID_U' for '$1' has more than five digits. Aborting." >/dev/stderr
		return 1
	}
	[ ${#TMP_NID_G} -gt 5 ] && {
		echo "$VAR_MYNAME: Error: numeric Group ID '$TMP_NID_G' for '$1' has more than five digits. Aborting." >/dev/stderr
		return 1
	}
	[ $TMP_NID_U -eq 0 ] && {
		echo "$VAR_MYNAME: Error: numeric User ID for '$1' may not be 0. Aborting." >/dev/stderr
		return 1
	}
	[ $TMP_NID_G -eq 0 ] && {
		echo "$VAR_MYNAME: Error: numeric Group ID for '$1' may not be 0. Aborting." >/dev/stderr
		return 1
	}

	local TMP_ADD_G="$4"
	if [ -n "$TMP_ADD_G" ]; then
		echo -n "$TMP_ADD_G" | LC_ALL=C grep -q -E "^([0-9a-z_,]|-)*$" || {
			echo "$VAR_MYNAME: Error: additional Group-Memberships '$TMP_ADD_G' container invalid characters. Aborting." >/dev/stderr
			return 1
		}
	fi

	_removeUserAndGroup "$1"

	getent passwd $TMP_NID_U >/dev/null 2>&1 && {
		echo "$VAR_MYNAME: Error: numeric User ID '$TMP_NID_U' already exists. Aborting." >/dev/stderr
		return 1
	}
	getent group $TMP_NID_G >/dev/null 2>&1 && {
		echo "$VAR_MYNAME: Error: numeric Group ID '$TMP_NID_G' already exists. Aborting." >/dev/stderr
		return 1
	}

	local TMP_ARG_ADD_GRPS=""
	[ -n "$TMP_ADD_G" ] && TMP_ARG_ADD_GRPS="-G $TMP_ADD_G"

	echo "$VAR_MYNAME: Setting numeric user/group ID of '$1' to ${TMP_NID_U}/${TMP_NID_G}..."
	groupadd -g ${TMP_NID_G} "$1" || {
		echo "$VAR_MYNAME: Error: could not create Group '$1'. Aborting." >/dev/stderr
		return 1
	}
	useradd -l -u ${TMP_NID_U} -g "$1" $TMP_ARG_ADD_GRPS -M -s /bin/false "$1" || {
		echo "$VAR_MYNAME: Error: could not create User '$1'. Aborting." >/dev/stderr
		return 1
	}
	return 0
}

# ----------------------------------------------------------------------
# Volumes

# @param string $1 Directory
# @param string $2 User
# @param string $3 Group
# @param string $4 Dir Perms
# @param string $5 File Perms
#
# @return void
function _dep_setOwnerAndPerms_recursive() {
	[ -d "$1" ] && {
		chown $2:$3 -R "$1"
		find "$1" -type d -exec chmod "$4" "{}" \;
		find "$1" -type f -exec chmod "$5" "{}" \;
	}
	return 0
}

# ----------------------------------------------------------------------

# changing the User/Group ID is also done by
#   files/lsio-baseimage_ubuntu_bionic/fs_root/etc/cont-init.d/10-adduser
# but we need the User/Group ID to be changed here for chown+chmod

_createUserGroup "redis" "${CF_SYSUSR_RED_USER_ID}" "${CF_SYSUSR_RED_GROUP_ID}" || {
	_sleepBeforeAbort
}

_dep_setOwnerAndPerms_recursive "/data" $CF_SYSUSR_RED_USER_ID $CF_SYSUSR_RED_GROUP_ID "750" "640"

# ----------------------------------------------------------------------

if [ -n "$CF_LANG" ]; then
	echo "$VAR_MYNAME: Updating locale with '$CF_LANG'..."
	export LANG=$CF_LANG
	export LANGUAGE=$CF_LANG
	export LC_ALL=$CF_LANG
	update-locale LANG=$CF_LANG || {
		_sleepBeforeAbort
	}
	update-locale LANGUAGE=$CF_LANG
	update-locale LC_ALL=$CF_LANG
	echo "export LANG=$CF_LANG" >> ~/.bashrc
	echo "export LANGUAGE=$CF_LANG" >> ~/.bashrc
	echo "export LC_ALL=$CF_LANG" >> ~/.bashrc
fi

if [ -n "$CF_TIMEZONE" ]; then
	[ ! -f "/usr/share/zoneinfo/$CF_TIMEZONE" ] && {
		echo "$VAR_MYNAME: Could not find timezone file for '$CF_TIMEZONE'. Aborting." >/dev/stderr
		_sleepBeforeAbort
	}
	echo "$VAR_MYNAME: Setting timezone to '$CF_TIMEZONE'..."
	export TZ=$CF_TIMEZONE
	ln -snf /usr/share/zoneinfo/$CF_TIMEZONE /etc/localtime
	echo $CF_TIMEZONE > /etc/timezone
fi

# ----------------------------------------------------------------------

TMP_ADD_ARG=""
[ "$1" = "redis-server" ] && TMP_ADD_ARG="--appendonly yes"
/usr/local/bin/docker-entrypoint-vendor.sh "$@" $TMP_ADD_ARG
