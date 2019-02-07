# Apache Docker images for Docksal

This image(s) is part of the [Docksal](http://docksal.io) image library.

## Versions

- apache2.4 (based on http:2.4-alpine)

## Features

- SSL enabled (self-signed cert)
- PHP handling via FastCGI (`mod_proxy_fcgi`)
- HTTP Basic Authentication
- Support for configuration overrides

## Document root

Apache `DocumentRoot` for the default virtual host can be set via `APACHE_DOCUMENTROOT`environment variable 
(defaults to `/var/www/docroot`). 

## FastCGI server endpoint

These images are set up to work with a FastCGI server and will not start without one.  
The FastCGI endpoint can be set via `APACHE_FCGI_HOST_PORT` environment variable (defaults to `cli:9000`).

## HTTP Basic Authentication

Use `APACHE_BASIC_AUTH_USER` and `APACHE_BASIC_AUTH_PASS` environment variables to set username and password.

Example with Docker Compose

```yaml
  ...
  environment:
    - APACHE_BASIC_AUTH_USER=user
    - APACHE_BASIC_AUTH_PASS=password
  ...
```

## Configuration overrides

Configuration overrides can be added to a Docksal project codebase.

Use `.docksal/etc/apache/httpd-vhost-overrides.conf` to override the default virtual host configuration:

```apacheconfig
DirectoryIndex index2.html
```

Use `.docksal/etc/apache/httpd-vhosts.conf` to define additional virtual hosts:

```apacheconfig
<VirtualHost *:80>
	ServerName docs.test.docksal

	ProxyPass / http://docs.docksal.io/
	ProxyPassReverse / http://docs.docksal.io/
</VirtualHost>
```
