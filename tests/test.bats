#!/usr/bin/env bats

# Debugging
teardown() {
	echo
	# TODO: figure out how to deal with this (output from previous run commands showing up along with the error message)
	echo "Note: ignore the lines between \"...failed\" above and here"
	echo
	echo "Status: $status"
	echo "Output:"
	echo "================================================================"
	echo "$output"
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

# Global skip
# Uncomment below, then comment skip in the test you want to debug. When done, reverse.
#SKIP=1

@test "Bare server" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
	fin docker run --name "$NAME" -d -p 2580:80 -p 25443:443 \
		"$IMAGE"
	_healthcheck_wait

	### Tests ###

	run curl -sSk -I http://test.docksal:2580
	echo "$output" | grep "HTTP/1.1 200 OK"

	run curl -sSk https://test.docksal:25443
	echo "$output" | grep "It works!"

	run curl -sSk -I https://test.docksal:25443
	echo "$output" | grep "HTTP/1.1 200 OK"

	run curl -sSk https://test.docksal:25443
	echo "$output" | grep "It works!"

	run curl -sSk -I http://test.docksal:2580/nonsense
	echo "$output" | grep "HTTP/1.1 404 Not Found"


	### Cleanup ###
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
}

@test "Docroot mount" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
	fin docker run --name "$NAME" -d -p 2580:80 -p 25443:443 \
		-v $(pwd)/../tests/docroot:/var/www/docroot \
		"$IMAGE"
	_healthcheck_wait

	### Tests ###

	run curl -sSk -I http://test.docksal:2580
	echo "$output" | grep "HTTP/1.1 200 OK"

	run curl -sSk http://test.docksal:2580
	echo "$output" | grep "index.html"


	### Cleanup ###
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
}

@test "Docroot path override" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
	fin docker run --name "$NAME" -d -p 2580:80 -p 25443:443 \
		-v $(pwd)/../tests/docroot:/var/www/html \
		-e APACHE_DOCUMENTROOT=/var/www/html \
		"$IMAGE"
	_healthcheck_wait

	### Tests ###

	run curl -sSk -I http://test.docksal:2580
	echo "$output" | grep "HTTP/1.1 200 OK"

	run curl -sSk http://test.docksal:2580
	echo "$output" | grep "index.html"


	### Cleanup ###
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
}

@test "Basic HTTP Auth" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
	fin docker run --name "$NAME" -d -p 2580:80 -p 25443:443 \
		-v $(pwd)/../tests/docroot:/var/www/docroot \
		-e APACHE_BASIC_AUTH_USER=user \
		-e APACHE_BASIC_AUTH_PASS=pass \
		"$IMAGE" >/dev/null
	_healthcheck_wait

	### Tests ###

	# Check authorization is required
	run curl -sSk -I http://test.docksal:2580
	# Apache 2.2 returns "HTTP/1.1 401 Authorization Required" while Apache 2.4 returns "HTTP/1.1 401 Unauthorized"
	if [[ "$NAME" == "docksal-apache-2.2" ]]; then
		echo "$output" | grep "HTTP/1.1 401 Authorization Required"
	else
		echo "$output" | grep "HTTP/1.1 401 Unauthorized"
	fi

	# Check we can pass authorization
	run curl -sSk -I -u user:pass http://test.docksal:2580
	echo "$output" | grep "HTTP/1.1 200 OK"


	### Cleanup ###
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
}

@test "Configuration overrides" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
	fin docker run --name "$NAME" -d -p 2580:80 -p 25443:443 \
		-v $(pwd)/../tests/docroot:/var/www/docroot \
		-v $(pwd)/../tests/config:/var/www/.docksal/etc/apache \
		"$IMAGE" >/dev/null
	_healthcheck_wait

	### Tests ###

	# Test default virtual host config overrides
	run curl -sSk -I http://test.docksal:2580
	echo "$output" | grep "HTTP/1.1 200 OK"

	run curl -sSk http://test.docksal:2580
	echo "$output" | grep "index2.html"

	# Test extra virtual hosts config
	run curl -sSk -I http://docs.test.docksal:2580
	echo "$output" | grep "HTTP/1.1 301"

	run curl -sSk -L http://docs.test.docksal:2580
	echo "$output"| grep "Docksal Documentation"


	### Cleanup ###
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
}
