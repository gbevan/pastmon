#!/bin/bash -e

# dbhost & dbport are passed from unit file
#   start-pastmon-sensor.sh "dbhost=...; dbport=5432"

PARMS=$1
shift
eval $PARMS

if [ "$dbhost" == "" ]
then
  echo "ERROR: dbhost not provided from pastmon-web-discovery sidekick via etcd, PARMS: $PARMS" >&2
  exit 1
fi

sed -i \
  -e "s?[/ ]*\\(host = \\).*?\\1\"$dbhost\";?" \
  -e "s?[/ ]*\\(port = \\).*?\\1\"$dbport\";?" \
  -e "s?[/ ]*\\(password = \\).*?\\1\"pastmon\";?" \
  /usr/local/pastmon/etc/pastmon.conf

while [ 1 == 1 ]
do
  echo `date` "Starting PasTmon"
  /usr/local/pastmon/bin/pastmon -D -p $*
  sleep 5
done
