#!/bin/bash

cd

CRONTAB_FILE=$PWD/mycron
MANEYKO_HOME=/home/maneyko
MANEYKO_COM=$MANEYKO_COM/www/maneyko.com

root_setup() {
  apt-get update
  apt-get install -y \
    build-essential \
    bash \
    certbot \
    curl \
    fail2ban \
    git \
    less \
    libpq-dev \
    jq \
    postgresql-client \
    make \
    tmux \
    nginx \
    php-common \
    php-fpm \
    silversearcher-ag \
    vim \
    wget

  service nginx restart

  git clone https://github.com/maneyko/dotfiles
  ./dotfiles/install.sh

  source $HOME/.bashrc
  cat << EOT >> $CRONTAB_FILE
0 2  *   * * journalctl --vacuum-time=2d
0 2  *   * * sync && echo 3 > /proc/sys/vm/drop_caches
EOT
  crontab $CRONTAB_FILE
}

setup_maneyko() {
  adduser maneyko
  usermod -aG sudo maneyko

  mkdir -p $MANEYKO_HOME/.ssh

  cp $HOME/.ssh/authorized_keys $MANEYKO_HOME/.ssh/
  chown -R maneyko:maneyko $MANEYKO_HOME/.ssh

  cat << EOT > "$MANEYKO_HOME/.bashrc.local.preload"
user_color=154
host_color=26
host_text="DigitalOcean"
EOT
  chown maneyko:maneyko "$MANEYKO_HOME/.bashrc.local.preload"
}

setup_maneyko_com() {
  mkdir -p "$MANEYKO_COM"
  cd "$(dirname "$MANEYKO_COM")"
  rm -fr maneyko.com

  git clone https://github.com/maneyko/maneyko.com

  chown -R maneyko:maneyko $MANEYKO_COM

  cd /etc/fail2ban
  ln -s "$MANEYKO_COM/config/fail2ban/jail.local"

  cd /etc/letsencrypt
  wget https://raw.githubusercontent.com/certbot/certbot/HEAD/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf

  cd /etc/nginx/snippets
  for snippet in $MANEYKO_COM/config/nginx/snippets/*; do
    ln -s "$snippet"
  done

  cd /etc/nginx/
  rm sites-available/*
  rm sites-enabled/*
  cd sites-enabled/

  ln -s $MANEYKO_COM/config/nginx/default
  ln -s $MANEYKO_COM/config/nginx/maneyko.conf

  cp -r $MANEYKO_COM/scripts/godaddy/ $HOME/
  cd $HOME/godaddy
  rm certbot*.txt

  cat << EOT >> "$CRONTAB_FILE"
0 5  1   1,2,3,4,5,6,7,8,9,10,11,12 * /bin/bash -l -c '$HOME/godaddy/certbot-renew-wildcard.sh && service nginx restart'
EOT
  crontab $CRONTAB_FILE
  ./certbot-renew-wildcard.sh
  service nginx restart
}

main() {
  root_setup
  setup_maneyko
  setup_maneyko_com
}
