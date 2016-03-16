#!/bin/bash
set -o errexit
cd $(dirname $0)/..
source test/db-common.sh

# set db connection for if running in a separate container or not
dbconn="-u root"
if [[ ! -z "$MYSQL_CONTAINER" ]]; then
	dbconn="-u root -h mysql --port 3306"
fi

# MariaDB sets the default binlog_format to STATEMENT,
# which causes warnings that fail tests. Instead set it
# to the format we use in production, MIXED.
mysql $dbconn -e "SET GLOBAL binlog_format = 'MIXED';"

# Drop all users to get a fresh start
mysql $dbconn < test/drop_users.sql

for svc in $SERVICES; do
	for dbenv in $DBENVS; do
		(
		db="boulder_${svc}_${dbenv}"
		create_script="drop database if exists \`${db}\`; create database if not exists \`${db}\`;"

		mysql $dbconn -e "$create_script" || die "unable to create ${db}"

		echo "created empty ${db} database"

		goose -path=./$svc/_db/ -env=$dbenv up || die "unable to migrate ${db}"
		echo "migrated ${db} database"

		# With MYSQL_CONTAINER, patch the GRANT statements to
		# use 127.0.0.1, not localhost, as MySQL may interpret
		# 'username'@'localhost' to mean only users for UNIX
		# socket connections.
		USERS_SQL=test/${svc}_db_users.sql
		if [[ -f $USERS_SQL ]]; then
			if [[ $MYSQL_CONTAINER ]]; then
				sed -e "s/'localhost'/'127.0.0.1'/g" < $USERS_SQL | \
					mysql $dbconn -D $db || \
					die "unable to add users to ${db}"
			else
				mysql $dbconn -D $db < $USERS_SQL || \
					die "unable to add users to ${db}"
			fi
			echo "added users to ${db}"
		fi
		) &
	done
done
wait

echo "created all databases"
