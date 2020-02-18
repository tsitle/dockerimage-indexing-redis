ARG CF_REDIS_VERSION

# ----------------------------------------------------------------
# ----------------------------------------------------------------

# Docker Official Image
#   https://hub.docker.com/_/redis
FROM redis:${CF_REDIS_VERSION}-buster

#VOLUME /data
#WORKDIR /data

#COPY docker-entrypoint.sh /usr/local/bin/
#ENTRYPOINT ["docker-entrypoint.sh"]

#EXPOSE 6379
#CMD ["redis-server"]

# ----------------------------------------------------------------
# ----------------------------------------------------------------

# set environment variables
ENV DEBIAN_FRONTEND="noninteractive"
ENV \
	HOME="/root" \
	LANGUAGE="en_US.UTF-8" \
	LANG="en_US.UTF-8" \
	TERM="xterm"
ENV LC_ALL="en_US.UTF-8"

RUN \
	apt-get update \
	&& apt-get upgrade -y \
	&& apt-get dist-upgrade -y \
	&& apt-get install -y --no-install-recommends \
			apt-utils \
			locales \
			curl \
			tzdata \
			nano \
			less \
			wget \
			ca-certificates \
			iproute2 \
			procps \
	|| exit 1; \
	#
	echo "**** generate locale ****"; \
	sed -i'' \
			-e 's/# de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' \
			-e 's/# de_DE ISO-8859-1/de_DE ISO-8859-1/' \
			-e 's/# de_DE@euro ISO-8859-15/de_DE@euro ISO-8859-15/' \
			-e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' \
			-e 's/# en_US ISO-8859-1/en_US ISO-8859-1/' \
			-e 's/# en_US@euro ISO-8859-15/en_US@euro ISO-8859-15/' \
			/etc/locale.gen \
	&& dpkg-reconfigure locales \
	|| exit 1; \
	#
	apt-get clean \
	&& rm -rf \
			/tmp/* \
			/var/lib/apt/lists/* \
			/var/tmp/*

#
ENV DEBIAN_FRONTEND=dialog

# copy bashrc
COPY --chown=0:0 files/bash/dot_bashrc /root/.bashrc

# startup script
RUN \
	mv /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint-vendor.sh

COPY files/docker-entrypoint.sh /usr/local/bin/

RUN \
	chmod 700 \
			/usr/local/bin/docker-entrypoint.sh \
	&& chown root:root \
			/usr/local/bin/docker-entrypoint.sh

#
WORKDIR /data
