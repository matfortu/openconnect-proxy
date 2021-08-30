# openconnect + tinyproxy + microsocks + ssh

This Docker image contains an [openconnect client](http://www.infradead.org/openconnect/) that can proxy connections through using most proxy-like connections:

- HTTP/HTTPS connections, via [tinyproxy proxy server](https://tinyproxy.github.io/) (default on port 8888) 
- SOCKS5 connections, via [microsocks proxy](https://github.com/rofl0r/microsocks) (default on port 8889)
- SSH tunneling, via [openssh](https://www.openssh.com/), (default on port 22)

# Requirements

If you don't want to set the environment variables on the command line
set the environment variables in a `.env` file:

```sh
OPENCONNECT_URL=<Gateway URL>
OPENCONNECT_USER=<Username>
OPENCONNECT_PASSWORD=<Password>
OPENCONNECT_OPTIONS=--authgroup <VPN Group> \
	--servercert <VPN Server Certificate> --protocol=<Protocol> \
	--reconnect-timeout 86400
```

_Don't use quotes around the values!_

See the [openconnect documentation](https://www.infradead.org/openconnect/manual.html) for available options. 

Either set the password in the `.env` file or leave the variable `OPENCONNECT_PASSWORD` unset, so you get prompted when starting up the container.

You can also use multi-factor one-time-password codes in two different ways. If your connection uses a time-based OTP (like Google Authenticator), you can provide the key, and the entrypoint will generate and provide the code whenever it tries to connect:


	OPENCONNECT_TOTP_SECRET=<Key for TOTP>

Otherwise, you can generate the one-time-password yourself and pass it when you start the server:

	OPENCONNECT_MFA_CODE=<Multi factor authentication code>

# Run container in foreground

To start the container in foreground run:

```sh
docker run -it --rm --privileged --env-file=.env \
	-p 8888:8888 -p 8889:8889 -p 2222:22 jakawell/openconnect-proxy:latest
```

The proxies are listening on ports 8888 (http/https), 8889 (socks), and 2222 (ssh).

Without using a `.env` file set the environment variables on the command line with the docker run option `-e`:

```sh
docker run … -e OPENCONNECT_URL=vpn.gateway.com/example \
	-e OPENCONNECT_OPTIONS='<Openconnect Options>' \
	-e OPENCONNECT_USER=<Username> …
```

# Run container in background

To start the container in daemon mode (background) set the `-d` option:

	docker run -d -it --rm …

In daemon mode you can view the stderr log with `docker logs`:

	docker logs `docker ps|grep "jakawell/openconnect-proxy"|awk -F' ' '{print $1}'`

# Use container with docker-compose

```yml
	vpn:
	  container_name: openconnect_vpn
	  image: jakawell/openconnect-proxy:latest
	  privileged: true
	  env_file:
	    - .env
	  ports:
	    - "8888:8888"
	    - "8889:8889"
			- "2222:22"
	  cap_add:
	    - NET_ADMIN
	  networks:
	    - mynetwork
```


Set the environment variables for _openconnect_ in the `.env` file again (or specify another file) and 
map the configured ports in the container to your local ports if you want to access the VPN 
on the host too when running your containers. Otherwise only the docker containers in the same
network have access to the proxy ports.

# Route traffic through VPN container

Let's say you have a `vpn` container defined as above, then add `network_mode` option to your other containers:

```yml
	depends_on:
	  - vpn
	network_mode: "service:vpn"
```

Keep in mind that `networks`, `extra_hosts`, etc. and `network_mode` are mutually exclusive!

# Configure proxy

The container is connected via _openconnect_ and now you can configure your browser
and other software to use one of the proxies (8888 for http/https or 8889 for socks).

For example FoxyProxy (available for Firefox, Chrome) is a suitable browser extension.

You may also set environment variables:

```sh
	export http_proxy="http://127.0.0.1:8888/"
	export https_proxy="http://127.0.0.1:8888/"
```

composer, git (if you don't use the git+ssh protocol, see below) and others use these.

# ssh through the proxy

You can connect to the server just as you would any SSH server. The username is `root` and the password is `vpnproxy`. The port is whatever you point the exposed port 22 when starting the image.

	ssh root@localhost -p 2222

# Build

You can build the container yourself with

	docker build -f build/Dockerfile -t jakawell/openconnect-proxy:custom ./build

# Support

You like using my work? Go support the [original dev](https://github.com/wazum/openconnect-proxy#support), not me! 


