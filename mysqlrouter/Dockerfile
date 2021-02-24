FROM debian:stretch-slim

RUN apt-get update && apt-get install -y --no-install-recommends wget lsb-release gnupg hostname
RUN wget --no-check-certificate https://dev.mysql.com/get/mysql-apt-config_0.8.13-1_all.deb && dpkg -i mysql-apt-config_0.8.13-1_all.deb
RUN apt-get update && apt-get install -y --no-install-recommends mysql-router mysql-shell mysql-client && rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["mysqlrouter"]
