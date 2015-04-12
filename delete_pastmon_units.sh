#!/bin/bash
#
# Delete all pastmon units and related docker instances/images.
#
# Usage:
#   ./delete_pastmon_units.sh [ -v | --volume ] [ -y | --yes ]
#
#   -v | --volume option also deletes persistent data volume (aka the database)
#   -y | --yes assume yes you want to do this
#

OPTS=`getopt -o yvh --long yes,volume,help -- "$@"`
if [ $? != 0 ]
then
  echo "Terminating..." >&2
  exit 1
fi

eval set -- "$OPTS"

Usage() {
  cat >&2 <<EOF
Usage:
  ./delete_pastmon_units.sh [ -v | --volume ]

-v | --volume option also deletes persistent data volume (aka the database)
-y | --yes assume yes you want to do this.
EOF
  exit 1
}

VOLUME=false
YES=false
HELP=false
while true
do
  case "$1" in
    -v | --volume)
      VOLUME=true
      shift
      ;;
    -y | --yes)
      YES=true
      shift
      ;;
    -h | --help)
      Usage
      ;;
    --)
      shift
      break
      ;;
    *)
      Usage
      ;;
  esac
done

if [ $YES == false ]
then
  echo "Are you _sure_ you want to do this? (y/N)"
  read ANS
  if [ "$ANS" != "y" ]
  then
    echo "Aborted..." >&2
    exit 1
  fi
fi

echo "Destroying pastmon instance units"
fleetctl destroy pastmon-sensor@{1..5}.service pastmon-web-discovery@1.service pastmon-web@1.service

echo "Destroying pastmon template units"
fleetctl destroy pastmon-sensor@.service pastmon-web-discovery@.service pastmon-web@.service

echo "Removing pastmon-sensor docker containers"
fleetctl list-machines | tail -n +2 | awk '{print $2;}' | \
      xargs -i@ ssh @ "docker ps -a | \
      grep -e 'pastmon-sensor' | \
      awk '{ print \$1; }' | \
      xargs -i% docker rm %"

echo "Removing pastmon-web docker container"
docker rm pastmon-web1

echo "Removing pastmon docker images"
fleetctl list-machines | tail -n +2 | awk '{print $2;}' \
      | xargs -i@ ssh @ "docker images | \
      grep -e 'pastmon' | \
      awk '{ printf \"%s:%s\n\",\$1,\$2;}' | \
      xargs -i% docker rmi % "

if [ $VOLUME == true ]
then
  echo "Removing pastmon-db persistent database volume (and container)"
  docker rm -v pastmon-db
fi
