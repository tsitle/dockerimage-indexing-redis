# Redis Data Structure Server Docker Image for AARCH64, ARMv7l, X86 and X64

## Inheritance and added packages
- Docker Official Image redis
	- apt-utils
	- ca-certificates
	- curl
	- less
	- locales
	- nano
	- tzdata
	- wget
	- iproute2
	- procps

## Docker Container usage
See the related GitHub repository [https://github.com/tsitle/dockercontainer-indexing-redis](https://github.com/tsitle/dockercontainer-indexing-redis)

## Docker Container configuration
- CF\_SYSUSR\_RED\_USER\_ID [int]: User-ID for user that ownes the database files
- CF\_SYSUSR\_RED\_GROUP\_ID [int]: Group-ID for group that ownes the database files
- CF\_LANG [string]: Language to use (en\_EN.UTF-8 or de\_DE.UTF-8)
- CF\_TIMEZONE [string]: Timezone (e.g. 'Europe/Berlin')
