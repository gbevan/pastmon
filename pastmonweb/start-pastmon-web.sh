#!/bin/bash -e

# supports optional dbport=nnn as parameter
#   start-pastmon-web.sh ["dbport=5432; webport=8080"] [pastmon|tcpdump-like parms...]

PARMS=$1
if [[ "$1" =~ ^dbport.*|webport.* ]]
then
  shift
  eval $PARMS
fi

echo `date` "Starting Syslog"
perl -i -pe 'BEGIN{undef $/;}s/^daemon.*xconsole/#xconsole removed by start-pastmon-web.sh\n/smg' /etc/rsyslog.d/50-default.conf
/etc/init.d/rsyslog start

echo `date` "Starting Cron"
/usr/sbin/cron

if [ ! -d /var/lib/postgresql/9.3/main ]
then
    mkdir -p /var/lib/postgresql/9.3/main
    mkdir -p /var/run/postgresql
    chown -R postgres:postgres /var/lib/postgresql /var/run/postgresql
    su postgres -c "/usr/lib/postgresql/9.3/bin/pg_ctl initdb -D /var/lib/postgresql/9.3/main"
fi

if [ "$dbport" != "" ]
then
  sed -i \
    -e "s/port = 5432/port = $dbport/" \
    -e "s/max_connections = .*/max_connections = 10000/" \
    /etc/postgresql/9.3/main/postgresql.conf
  sed -i \
    -e "s?[/ ]*\\(port = \\).*?\\1\"$dbport\";?" \
    /usr/local/pastmon/etc/pastmon.conf
fi

sed -i \
  -e "s?[/ ]*\\(host = \\).*?\\1\"localhost\";?" \
  -e "s?[/ ]*\\(password = \\).*?\\1\"pastmon\";?" \
  /usr/local/pastmon/etc/pastmon.conf

echo `date` "Starting PostgreSQL"
/etc/init.d/postgresql start

if
  su - postgres -c 'psql pastmon2 -c ""'
then
  echo `date` "Found existing pastmon database"
else
  echo `date` "Creating the pastmon database"
  /usr/local/pastmon/bin/postgresql_admin/create_database_summary
fi

echo `date` "Starting php-5-fpm"
/etc/init.d/php5-fpm start

echo `date` "Starting Nginx"
if [ "$webport" != "" ]
then
  sed -i "s/listen 8080/listen $webport/" /etc/nginx/sites-enabled/pastmon
  # *NB: Dockerfile EXPOSE 8080 is effectively being ignore due to container
  #      being bound to the parent host's ip namespace
fi
/etc/init.d/nginx start

while [ 1 == 1 ]
do
  echo `date` "Starting PasTmon"
  /usr/local/pastmon/bin/pastmon -D -p $*
  sleep 5
done
