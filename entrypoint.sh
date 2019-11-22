#!/bin/sh
set -e

INVOICENINJA_VERSION=4.5.16

if [ ! -d /var/www/app/public ]; then
  curl -o ninja.zip -SL https://download.invoiceninja.com/ninja-v${INVOICENINJA_VERSION}.zip \
      && unzip -q ninja.zip -d /var/www/ \
      && rm ninja.zip \
      && mv /var/www/ninja /var/www/app  \
      && mv /var/www/app/storage /var/www/app/docker-backup-storage  \
      && mv /var/www/app/public /var/www/app/docker-backup-public  \
      && mkdir -p /var/www/app/public/logo /var/www/app/storage \
      && touch /var/www/app/.env \
      && chmod -R 755 /var/www/app/storage  \
      && chown -R www-data:www-data /var/www/app/storage /var/www/app/bootstrap /var/www/app/public/logo /var/www/app/.env /var/www/app/docker-backup-storage /var/www/app/docker-backup-public\
      && rm -rf /var/www/app/docs /var/www/app/tests /var/www/ninja
fi

if [ ! -d /var/www/app/storage ]; then
	cp -Rp /var/www/app/docker-backup-storage /var/www/app/storage
else
	IN_STORAGE_BACKUP="$(ls /var/www/app/docker-backup-storage/)"
	for path in $IN_STORAGE_BACKUP; do
		if [ ! -e "/var/www/app/storage/$path" ]; then
			cp -Rp "/var/www/app/docker-backup-storage/$path" "/var/www/app/storage/"
		fi
	done
fi

if [ ! -d /var/www/app/public/logo ]; then
	cp -Rp /var/www/app/docker-backup-public/logo /var/www/app/public/logo
else
	IN_LOGO_BACKUP="$(ls /var/www/app/docker-backup-public/logo/)"
	for path in $IN_LOGO_BACKUP; do
		if [ ! -e "/var/www/app/public/logo/$path" ]; then
			cp -Rp "/var/www/app/docker-backup-public/logo/$path" "/var/www/app/public/logo/"
		fi
	done
fi

# compare public volume version with image version
if [ ! -e /var/www/app/public/version ] || [ "$INVOICENINJA_VERSION" != "$(cat /var/www/app/public/version)" ]; then
  echo 'clone public directory'
  cp -Rp /var/www/app/docker-backup-public/* /var/www/app/public/
  echo $INVOICENINJA_VERSION > /var/www/app/public/version
fi

# fix permission for monted directories
chown www-data:www-data /var/www/app/storage
chown	 www-data:www-data /var/www/app/public/logo

#php artisan optimize --force
#php artisan migrate --force

#if [ ! -e "/var/www/app/is-seeded" ]; then
	#php artisan db:seed --force
	#touch "/var/www/app/is-seeded"
#fi

#!/usr/bin/env bash
service nginx start
php-fpm