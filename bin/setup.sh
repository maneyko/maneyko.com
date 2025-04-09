#!/bin/bash

cd "$HOME"

CRONTAB_FILE=$PWD/mycron
MANEYKO_HOME=/home/maneyko
MANEYKO_COM=$MANEYKO_HOME/www/maneyko.com

main() {
  root_setup
  setup_maneyko
  setup_maneyko_com
  setup_xtables
}

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


  fallocate -l 512M /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  cp /etc/fstab /etc/fstab.bak
  echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

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

  usermod -a -G maneyko www-data

  git clone https://github.com/maneyko/maneyko.com

  chown -R maneyko:maneyko $MANEYKO_COM

  cd $MANEYKO_COM
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  php composer-setup.php
  mv composer.phar /usr/local/bin/composer
  composer install
  chown -R maneyko:maneyko vendor/

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

  # To get certificates for regular websites:
  #
  # domain_name="example.com"
  # certbot --nginx -d $domain_name -d www.$domain_name
}

# https://gist.github.com/woods/25ef91a95da85bf10974
# https://docs.rackspace.com/docs/block-ip-range-from-countries-with-geoip-and-iptables#install-xtables-addons
setup_xtables() {
  addons_directory=/usr/libexec/xtables-addons

  apt-get install xtables-addons-common libtext-csv-xs-perl linux-headers-$(uname -r)

  # Create the directory where the country data should live
  mkdir /usr/share/xt_geoip

  # Download and install the latest country data
  mkdir /tmp/xt_geoip_dl
  cd /tmp/xt_geoip_dl
  $addons_directory/xt_geoip_dl
  $addons_directory/xt_geoip_build -D /usr/share/xt_geoip *.csv

  cat << 'EOT' > $HOME/enable-us-only.sh
#!/bin/bash

sudo iptables -I INPUT -m geoip ! --src-cc US,ZZ -j DROP
EOT

  cat << 'EOT' > $HOME/disable-us-only.sh
#!/bin/bash

sudo iptables -D INPUT -m geoip ! --src-cc US,ZZ -j DROP
EOT

  # sudo apt-get install iptables-persistent
  # sudo netfilter-persistent save
}

main
