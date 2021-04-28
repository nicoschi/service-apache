#!/usr/bin/env bats

# Debugging
teardown () {
	echo
	echo "Output:"
	echo "================================================================"
	echo "${output}"
	echo "================================================================"
}

# Checks container health status (if available)
# @param $1 container id/name
_healthcheck ()
{
	local health_status
	health_status=$(docker inspect --format='{{json .State.Health.Status}}' "$1" 2>/dev/null)

	# Wait for 5s then exit with 0 if a container does not have a health status property
	# Necessary for backward compatibility with images that do not support health checks
	if [[ $? != 0 ]]; then
		echo "Waiting 10s for container to start..."
		sleep 10
		return 0
	fi

	# If it does, check the status
	echo $health_status | grep '"healthy"' >/dev/null 2>&1
}

# Waits for containers to become healthy
_healthcheck_wait ()
{
	# Wait for cli to become ready by watching its health status
	local container_name="${NAME}"
	local delay=5
	local timeout=30
	local elapsed=0

	until _healthcheck "$container_name"; do
		echo "Waiting for $container_name to become ready..."
		sleep "$delay";

		# Give the container 30s to become ready
		elapsed=$((elapsed + delay))
		if ((elapsed > timeout)); then
			echo "$container_name heathcheck failed"
			exit 1
		fi
	done

	return 0
}

# To work on a specific test:
# run `export SKIP=1` locally, then comment skip in the test you want to debug

@test "Bare service" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start

	run _healthcheck_wait
	unset output

	### Tests ###

	run curl -sSk -I http://test.docksal.site:2580
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	unset output

	run curl -sSk https://test.docksal.site:25443
	[[ "$output" =~ "It works!" ]]
	unset output

	run curl -sSk -I https://test.docksal.site:25443
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	unset output

	run curl -sSk https://test.docksal.site:25443
	[[ "$output" =~ "It works!" ]]
	unset output

	run curl -sSk -I http://test.docksal.site:2580/nonsense
	[[ "$output" =~ "HTTP/1.1 404 Not Found" ]]
	unset output


	### Cleanup ###
	make clean
}

@test "Docroot mount" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	VOLUMES="\
		-v $(pwd)/../tests/docroot:/var/www/docroot" \
		make start

	run _healthcheck_wait
	unset output

	### Tests ###

	run curl -sSk -I http://test.docksal.site:2580
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	unset output

	run curl -sSk http://test.docksal.site:2580
	[[ "$output" =~ "index.html" ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Docroot path override" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	VOLUMES="\
		-v $(pwd)/../tests/docroot:/var/www/html" \
	ENV="\
		-e APACHE_DOCUMENTROOT=/var/www/html" \
		make start

	run _healthcheck_wait
	unset output

	### Tests ###

	run curl -sSk -I http://test.docksal.site:2580
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	unset output

	run curl -sSk http://test.docksal.site:2580
	[[ "$output" =~ "index.html" ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Basic HTTP Auth" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	VOLUMES=" \
		-v $(pwd)/../tests/docroot:/var/www/docroot" \
	ENV=" \
		-e APACHE_BASIC_AUTH_USER=user \
		-e APACHE_BASIC_AUTH_PASS=pass" \
		make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# Check authorization is required
	run curl -sSk -I http://test.docksal.site:2580
	[[ "$output" =~ "HTTP/1.1 401 Unauthorized" ]]
	unset output

	# Check we can pass authorization
	run curl -sSk -I -u user:pass http://test.docksal.site:2580
	[[ "$output" =~ "HTTP/1.1 200 OK" ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Configuration overrides" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	VOLUMES=" \
		-v $(pwd)/../tests/docroot:/var/www/docroot \
		-v $(pwd)/../tests/config:/var/www/.docksal/etc/apache" \
		make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# Test default virtual host config overrides
	run curl -sSk http://test2.docksal.site:2580
	[[ "$output" =~ "index2.html" ]]
	unset output

	# Test extra virtual hosts config
	run curl -sSk -L http://test3.docksal.site:2580
	[[ "$output" =~ "index3.html" ]]
	unset output

	### Cleanup ###
	make clean
}
