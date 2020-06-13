#!/bin/sh

main() {
  get_config

  if [ $# -eq 0 ]; then
    rx
  else
    tx "$@"
  fi
}

get_config() {
  local CONFIG="$HOME/.aesnc.conf"
  PEER=""
  PORT=""
  SALT_LENGTH=""
  if [ -f "$CONFIG" ]; then
    . "$CONFIG"
  fi
  if [ -z "$PEER" ] || [ -z "$PORT" ] || [ -z "$SALT_LENGTH" ]; then
    echo "Your config file will now be recreated" >&2
    read -p "Please enter peer hostname (e.g., freemyip.com domain or IP): " PEER
    read -p "Please enter port number (e.g., 12345): " PORT
    cat <<EOF > "$CONFIG"
PEER="$PEER"
PORT="$PORT"
SALT_LENGTH="16"
EOF
    . "$CONFIG"
  fi

  PASSWORD="$HOME/.aesnc.passwd"
  local RAND="`head -c 16 /dev/urandom | hexdump -e '16/1 "%02x" "\n"'`"
  if ! [ -f "$PASSWORD" ]; then
    read -p "Please enter new password (e.g., $RAND): " RAND
    echo "$RAND" > "$PASSWORD"
  fi
}

connect() {
  nc -q 5 -w 120 -vv "$PEER" "$PORT" ||
  nc -q 5 -w 120 -vv -l "$PORT"
}

aes() {
  aespipe -P "$PASSWORD" "$@"
}

tx() {
  {
    head -c "$SALT_LENGTH" /dev/urandom
    tar -cv "$@"
  } |
  aes |
  connect
}

rx() {
  pwd
  connect |
  aes -d |
  {
    head -c "$SALT_LENGTH" > /dev/null
    tar -xv
  }
}

main "$@"
