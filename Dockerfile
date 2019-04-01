FROM ubuntu:18.04
MAINTAINER elias.kotlyar@gmail.com


RUN echo 'phpmyadmin phpmyadmin/dbconfig-install boolean false' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
RUN apt-get update && apt-get install -y tzdata

RUN apt-get update && \
    apt-get install -y \
      wget \
      curl \
      iputils-ping \
      nano \
      apache2 \
      php7.2 \
      php7.2-cli \
      libapache2-mod-php7.2 \
      php7.2-gd \
      php7.2-json \
      php7.2-ldap \
      php7.2-mbstring \
      php7.2-mysql \
      php7.2-pgsql \
      php7.2-sqlite3 \
      php7.2-xml \
      php7.2-xsl \
      php7.2-zip \
      php7.2-soap \
      php7.2-curl \
      php7.2-intl \
      php-xdebug \
      phpmyadmin \
      p7zip \
      composer \
      openssh-server

RUN rm /etc/apache2/conf-available/phpmyadmin.conf
RUN ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf

COPY scripts/phpmyadminautologin.php /etc/phpmyadmin/conf.d/autologin.php

COPY virtualhost.conf /etc/apache2/sites-available/000-default.conf
COPY run /usr/local/bin/run
RUN chmod +x /usr/local/bin/run
RUN a2enmod rewrite

# PHP Settings:

COPY scripts/phpsettings.sh /tmp/phpsettings.sh
RUN chmod +x /tmp/phpsettings.sh
RUN /tmp/phpsettings.sh

# Magerun

COPY scripts/n98-magerun.sh /tmp/n98-magerun.sh
RUN chmod +x /tmp/n98-magerun.sh
RUN /tmp/n98-magerun.sh


# n98-magerun

COPY scripts/mailcatcher.sh /tmp/mailcatcher.sh
RUN chmod +x /tmp/mailcatcher.sh
RUN /tmp/mailcatcher.sh

# Ioncube:
COPY ioncube_loader_lin_7.2.so /usr/lib/php/ioncube_loader_lin_7.2.so

# MailCatcher:


apt-get install -y libsqlite3-dev ruby-dev ruby gcc make g++
gem install -V mailcatcher

# Add config to mods-available for PHP
# -f flag sets "from" header for us
touch /etc/php/7.0/mods-available/mailcatcher.ini
echo "sendmail_path = /usr/bin/env $(which catchmail) -f test@local.dev" | tee /etc/php/7.0/mods-available/mailcatcher.ini
# Enable sendmail config for all php SAPIs (apache2, fpm, cli)
phpenmod mailcatcher

# Apache Configuration:
a2enmod proxy
a2enmod proxy_http


MAILCATCHERCONFIG=$(cat <<EOF
ProxyRequests Off
ProxyPass /mailcatcher http://127.0.0.1:1080/
ProxyPass /assets http://127.0.0.1:1080/assets
ProxyPass /messages http://127.0.0.1:1080/messages

#SetEnv force-proxy-request-1.0 1
#SetEnv proxy-nokeepalive 1



EOF
)
echo "$MAILCATCHERCONFIG" > /etc/apache2/conf-available/mailcatcher.conf
a2enconf mailcatcher
# mailcatcher






RUN echo 'cd /var/www' >> /root/.bashrc

ENV TERM xterm

RUN mkdir /var/run/sshd

RUN echo 'root:root' |chpasswd

RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config


EXPOSE 22
EXPOSE 80
EXPOSE 443
CMD ["/usr/local/bin/run"]
