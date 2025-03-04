FROM alpine:latest

RUN apk add --no-cache libcrypto1.1 libssl1.1 libstdc++ --repository http://dl-cdn.alpinelinux.org/alpine/edge/main
RUN apk add --no-cache oath-toolkit-libpskc --repository http://dl-cdn.alpinelinux.org/alpine/edge/community
RUN apk add --no-cache nettle --repository http://dl-cdn.alpinelinux.org/alpine/edge/main
# openconnect is not yet available on main
RUN apk add --no-cache openconnect tinyproxy --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing
RUN apk add --no-cache ca-certificates wget \
    && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r0/glibc-2.35-r0.apk \
    && apk add --force-overwrite --no-cache --virtual .build-deps glibc-2.35-r0.apk gcc make musl-dev \
    && cd /tmp \
    && wget https://github.com/rofl0r/microsocks/archive/v1.0.3.tar.gz \
    && tar -xzvf v1.0.3.tar.gz \
    && cd microsocks-1.0.3 \
    && make \
    && make install \
    # add vpn-slice with dependencies (dig) https://github.com/dlenski/vpn-slice
    && apk add --no-cache python3 py3-pip bind-tools && pip3 install --upgrade pip \
    && pip3 install https://github.com/dlenski/vpn-slice/archive/master.zip \
    # get totp tool
    && apk add --no-cache oath-toolkit-oathtool \
    && apk del .build-deps wget \
    && apk add --no-cache cntlm
# Use an up-to-date version of vpnc-script
# https://www.infradead.org/openconnect/vpnc-script.html
COPY build/vpnc-script /etc/vpnc/vpnc-script
RUN chmod 755 /etc/vpnc/vpnc-script
COPY build/tinyproxy.conf /etc/tinyproxy.conf
COPY build/entrypoint.sh /entrypoint.sh
COPY build/cntlm.conf /etc/cntlm.conf.bk
RUN chmod +x /entrypoint.sh
EXPOSE 8888
EXPOSE 8889
EXPOSE 3128
ENTRYPOINT ["/entrypoint.sh"]
