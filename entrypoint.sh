#!/bin/sh

set -e

DATA_DIR="/data"

elog() {
  COMPONENT="${1}"
  shift
  echo "[${COMPONENT}]" "${@}"
}

_configure_proxy() {
  elog "Proxy" "configuring proxy"
  cat << EOF > /etc/nginx/http.d/default.conf
server {
	listen 127.0.0.1:8080 default_server;

	server_name _;

	location / {
    proxy_pass ${STREAM_URL};
    proxy_buffering off;
    proxy_ssl_server_name on;
#    proxy_http_version 1.1;
	}
}
EOF
}

_start_streamripper() {
  elog "Streamripper" "running"
  rm -rf /data/incomplete
  URL="${1}"
  shift
  exec streamripper "${URL}" -s -u "${USER_AGENT}" -d "${DATA_DIR}" "$@"
}

_start_ripping() {
  case "${STREAM_URL}" in
    "https://"*)
      _start_streamripper "http://127.0.0.1:8080" "$@"
      ;;
    *) _start_streamripper "${STREAM_URL}" "$@";;
  esac
}

_waiter() {
  trap '{ kill $worker_pid; wait; exit 0; }' INT TERM

  while :;
  do
    _start_ripping "$@" &
    worker_pid=$!

    elog "Waiter" "waiting for ${REQUIRED_COLLECTED_MB}MB of collected music..."
    while :;
    do
      if inotifywait -qq -e moved_to "${DATA_DIR}";
      then
        collected_mb=$(du -ms "${DATA_DIR}" | awk '{ print $1 }')
        if [ $collected_mb -ge $REQUIRED_COLLECTED_MB ];
        then
          elog "Waiter" "collected ${collected_mb}MB of music, stopping ripping process."
          kill $worker_pid
          break
        else
          elog "Waiter" "collected ${collected_mb}MB of ${REQUIRED_COLLECTED_MB}MB music, continuing."
        fi
      fi
    done

    while :;
    do
      if inotifywait -qq -e moved_from -e delete "${DATA_DIR}";
      then
        if [ $(du -ms "${DATA_DIR}" | awk '{ print $1 }') -lt $REQUIRED_COLLECTED_MB ];
        then
          elog "Waiter" "collection size decreased, starting ripping process."
          break
        fi
      fi
    done
  done
}

_initialize() {
  case "${STREAM_URL}" in
    "https://"*)
      _configure_proxy
      nginx
      ;;
  esac
}

_initialize

if [ "x${REQUIRED_COLLECTED_MB}" != "x" ];
then
  _waiter "$@"
else
  _start_ripping "$@"
fi
