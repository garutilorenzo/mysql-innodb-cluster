#!/bin/bash
set -eo pipefail
shopt -s nullglob

# check to see if this file is being run or sourced from another script
_is_sourced() {
	# https://unix.stackexchange.com/a/215279
	[ "${#FUNCNAME[@]}" -ge 2 ] \
		&& [ "${FUNCNAME[0]}" = '_is_sourced' ] \
		&& [ "${FUNCNAME[1]}" = 'source' ]
}

_main() {
	# if command starts with an option, prepend mysqld
	if [ "${1:0:1}" = '-' ]; then
		set -- mysqld "$@"
	fi

	# skip setup if they aren't running mysqld or want an option that stops mysqld
	if [ "$1" = 'mysqlrouter' ]; then
		echo 'Setting up a new router instance...'

		# we need to ensure that they've specified a boostrap URI
		if [ -z "$MYSQL_HOST" -a -z "$MYSQL_PASSWORD" ]; then
			echo >&2 'error: You must specify a value for MYSQL_HOST and MYSQL_PASSWORD (MYSQL_USER=root is the default) when setting up a router'
			exit 1
		fi

		if [ -z "$CLUSTERMEMBERS" ]; then
			echo >&2 'error: You must specify a value for CLUSTERMEMBERS when setting up a router'
			exit 1
		fi

		if [ -z "$MYSQL_PORT" ]; then
			MYSQL_PORT="3306"
		fi

		if [ -z "$MYSQL_USER" ]; then
			MYSQL_USER="root"
		fi

		if [ -z "$CLUSTER_NAME" ]; then
			CLUSTER_NAME="testcluster"
		fi

		until mysql --no-defaults -h "$MYSQL_HOST" -P"$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD" -nsLNE -e 'exit'; do
			>&2 echo "MySQL is unavailable - sleeping"
			sleep 5
		done

		>&2 echo "MySQL is up"

		local i
		for i in {60..0}; do
			# only use the root password if the database has already been initializaed
			# so that it won't try to fill in a password file when it hasn't been set yet
			echo "Waiting for cluster members..."

			READY=$(mysql --no-defaults -h "$MYSQL_HOST" -P"$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD" -nsLNE -e "select count(*) from performance_schema.replication_group_members where MEMBER_STATE = 'ONLINE';" 2>/dev/null | grep -v '*')

			if [ "$READY" -eq "$CLUSTERMEMBERS" ]; then
				break
			fi
			sleep 1
		done

		if [ "$i" = 0 ]; then
			echo "Unable to start mysqlrouter."
		fi

		# We'll use the hostname as the router instance name
		HOSTNAME=$(hostname)

		HOSTPORT=$(mysql --no-defaults -h "$MYSQL_HOST" -P"$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD" -nsLNE -e "select CONCAT(member_host, ':', member_port) as primary_host from performance_schema.replication_group_members where member_state='ONLINE' and member_id=(IF((select @grpm:=variable_value from performance_schema.global_status where variable_name='group_replication_primary_member') = '', member_id, @grpm)) limit 1" 2>/dev/null | grep -v '*')

		set +e
		metadata_exists=$(mysqlsh --uri="$MYSQL_USER"@"$MYSQL_HOST":"$MYSQL_PORT" -p"$MYSQL_ROOT_PASSWORD" --no-wizard --js -i -e "dba.getCluster( '${CLUSTER_NAME}' )" 2>&1 | grep "<Cluster:$CLUSTER_NAME>")
		set -e

		if [ -z "$metadata_exists" ]; then
			# Then let's create the innodb cluster metadata
			output=$(mysqlsh --uri="$MYSQL_USER"@"$HOSTPORT" -p"$MYSQL_ROOT_PASSWORD" --no-wizard --js -i -e "dba.createCluster('${CLUSTER_NAME}', {adoptFromGR: true})")
		fi

		output=$(echo "$MYSQL_ROOT_PASSWORD" | mysqlrouter --bootstrap="$MYSQL_USER"@"$HOSTPORT" --user=root --name "$HOSTNAME" --force)

		if [ ! "$?" = "0" ]; then
			echo >&2 'error: could not bootstrap router:'
			echo >&2 "$output"
			exit 1
		fi
	fi
	exec "$@"
}
# If we are sourced from elsewhere, don't perform any further actions
if ! _is_sourced; then
	_main "$@"
fi
