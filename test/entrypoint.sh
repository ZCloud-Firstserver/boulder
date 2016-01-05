#!/bin/bash

set -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# start rsyslog
service rsyslog start &&

# make sure we can reach the mysqldb
# see http://tldp.org/LDP/abs/html/devref1.html for description of this syntax.
if [[ -z "$MYSQL_CONTAINER" ]]; then
  while ! exec 6<>/dev/tcp/0.0.0.0/3306; do
      echo "$(date) - still trying to connect to mysql at 0.0.0.0:3306"
      sleep 1
  done

  # make sure we can reach the rabbitmq
  while ! exec 6<>/dev/tcp/0.0.0.0/5672; do
      echo "$(date) - still trying to connect to rabbitmq at 0.0.0.0:5672"
      sleep 1
  done

  exec 6>&-
  exec 6<&-
else
  until /usr/bin/mysql -h mysql; do
      echo "$(date) - still trying to connect to mysql"
      sleep 1
  done
fi

# create the database
source $DIR/create_db.sh
$DIR/setup.sh

# Set up rabbitmq exchange and activity monitor queue
go run cmd/rabbitmq-setup/main.go -server amqp://localhost

$@
