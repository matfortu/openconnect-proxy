#!/bin/sh

sed "s/^Port .*$/Port 8888/" -i /etc/tinyproxy.conf
/usr/bin/tinyproxy -c /etc/tinyproxy.conf

/usr/local/bin/microsocks -i 0.0.0.0 -p 8889 &

cat /etc/cntlm.conf.bk | sed "s/\bProxy\b/Proxy $PROXY/" | sed "s/\bProxy1\b/Proxy $PROXY1/" | sed "s/\bProxy2\b/Proxy $PROXY2/" | sed "s/\bProxy3\b/Proxy $PROXY3/" > /etc/cntlm.conf
sed "s/\bUsername\b/Username $OPENCONNECT_USER/" -i /etc/cntlm.conf
sed "s/\bDomain\b/Domain $DOMAIN/" -i /etc/cntlm.conf
sed "s/\bPassword\b/Password $NTLM_PROXY_PASS/" -i /etc/cntlm.conf

/usr/sbin/cntlm &

run () {
  # Start openconnect
  if [[ -z "${OPENCONNECT_PASSWORD}" ]]; then
  # Ask for password
    openconnect -u $OPENCONNECT_USER $OPENCONNECT_OPTIONS $OPENCONNECT_URL
  elif [[ ! -z "${OPENCONNECT_PASSWORD}" ]] && [[ ! -z "${OPENCONNECT_MFA_CODE}" ]]; then
  # Multi factor authentication (MFA)
    (echo $OPENCONNECT_PASSWORD; echo $OPENCONNECT_MFA_CODE) | openconnect -u $OPENCONNECT_USER $OPENCONNECT_OPTIONS --passwd-on-stdin $OPENCONNECT_URL
  elif [[ ! -z "${OPENCONNECT_PASSWORD}" ]] && [[ ! -z "${OPENCONNECT_TOTP_SECRET}" ]]; then
  # Time-based One Time Password (TOTP, "Google Authenticator")
    OPENCONNECT_TOTP=$(oathtool --time-step-size 60s --digits 6 --totp=SHA1 --base32 "$OPENCONNECT_TOTP_SECRET")
    echo -e "$OPENCONNECT_TOTP\n$OPENCONNECT_PASSWORD\n" | openconnect -u $OPENCONNECT_USER $OPENCONNECT_OPTIONS --passwd-on-stdin $OPENCONNECT_URL
  elif [[ ! -z "${OPENCONNECT_PASSWORD}" ]]; then
  # Standard authentication
    echo $OPENCONNECT_PASSWORD | openconnect -u $OPENCONNECT_USER $OPENCONNECT_OPTIONS --passwd-on-stdin $OPENCONNECT_URL
  fi
}

until (run); do
  echo "openconnect exited. Restarting process in 30 seconds…" >&2
  sleep 30
done
