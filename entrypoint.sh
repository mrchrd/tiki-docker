#!/bin/bash
set -eux

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

tiki_console() {
  sudo -Eu www-data php -q -d memory_limit=256M /var/www/html/console.php $@
}

tiki_database_install() {
  timeout=300
  start_time=$(date +%s)

  while true; do
    output=$(tiki_console database:install)

    if echo "$output" | grep -q "Installation completed successfully"; then
      break
    fi

    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    if [ $elapsed_time -ge $timeout ]; then
      return 1
    fi

    sleep 2
  done

  return 0
}

tiki_database_update() {
  timeout=300
  start_time=$(date +%s)

  while true; do
    output=$(tiki_console database:update)

    if echo "$output" | grep -q "Update completed"; then
      break
    fi

    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    if [ $elapsed_time -ge $timeout ]; then
      return 1
    fi

    sleep 2
  done

  return 0
}

TIKI_SKIP_INSTALL="${TIKI_SKIP_INSTALL:-false}"
case "${TIKI_SKIP_INSTALL,,}" in
  y | yes | true | 1)
    TIKI_SKIP_INSTALL=true
    ;;
  *)
    TIKI_SKIP_INSTALL=false
    ;;
esac

TIKI_VERSION=$(tiki_console tiki:info | awk '/^Tiki version:/{print $NF}')

env | grep "^TIKI_" >> /etc/environment || true

if [ -z "${TIKI_VERSION}" ] && [ "${1}" = "php-fpm" ] && ! ${TIKI_SKIP_INSTALL}; then
  tiki_database_install

  tiki_console preferences:set fgal_batch_dir ../tikifiles/fgal_batch_dir
  tiki_console preferences:set fgal_preserve_filenames y
  tiki_console preferences:set fgal_use_db n
  tiki_console preferences:set fgal_use_dir ../tikifiles/fgal_use_dir
  tiki_console preferences:set gal_use_db n
  tiki_console preferences:set gal_use_dir ../tikifiles/gal_use_dir
  tiki_console preferences:set t_use_db n
  tiki_console preferences:set t_use_dir ../tikifiles/t_use_dir
  tiki_console preferences:set tmpDir /var/www/html/temp
  tiki_console preferences:set uf_use_db n
  tiki_console preferences:set uf_use_dir ../tikifiles/uf_use_dir
  tiki_console preferences:set w_use_db n
  tiki_console preferences:set w_use_dir ../tikifiles/w_use_dir

  tiki_console preferences:set browsertitle "${TIKI_TITLE:-Tiki}"
  tiki_console preferences:set language "${TIKI_LANG:-en}"
  tiki_console preferences:set sender_email "${TIKI_SENDER_EMAIL:-no-reply@tiki.localhost}"
  tiki_console preferences:set server_domain "${TIKI_DOMAIN:-tiki.localhost}"

  tiki_console users:password admin "${TIKI_ADMIN_PASS:-tikiwiki}"

  tiki_console index:rebuild
  tiki_console installer:lock
fi

exec "$@"
