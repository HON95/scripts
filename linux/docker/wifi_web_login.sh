#!/usr/bin/env bash

# Author: HON
# WiFi web login script R2
#
# Requires BASH, cURL
#
# $user, $pass, $test_url and $login_url have been hidden

# Constants
color_green='\e[32m'
color_red='\e[31m'
color_yellow='\e[33m'
color_end='\e[0m'
status_unknown=0
status_no_con=1
status_connected=2
status_logging_in=3
status_login_failed=4

# Credentials
user=''
pass=''

# Configuration
debug=0
sleep_time_default=1
sleep_time_login=1
sleep_time_login_failed=60
sleep_time_no_con=5
max_time_test=5
max_time_login=15
test_url='' # Can not naturally redirect
login_url=''
header_connection='Connection: close'
header_user_agent='Login script'
header_content_type='application/x-www-form-urlencoded'
data="login=true&auth_user=${user}&auth_pass=${pass}&redirurl"%"2F=&accept=Continue"

# State variables
test_http_code=''
login_http_code=''
status=''
last_status='0'

# Check if BASH shell
if ! test -n "$BASH_VERSION"; then
  echo >&2 "This script requires BASH."
  exit
fi

# Check if cURL is available
hash curl 2>/dev/null || {
  echo >&2 "This script requires cURL."
  exit 1
}

function test_connection {
  curl -o /dev/null --max-time $max_time_test --silent --insecure --head --write-out '%{http_code}\n' $test_url
}

function test_connection_debug {
  curl --head --insecure $test_url
}

function login {
  curl  -o /dev/null  --max-time $max_time_login --silent --insecure --write-out '%{http_code}\n' -H "$header_connection" -H "$header_user_agent" -H "$header_content_type" --data "$data" "$login_url"
}

function login_debug {
  curl -i --insecure -H "$header_connection" -H "$header_user_agent" -H "$header_content_type" --data "$data" "$login_url"
}

function print_status {
  prefix="[$(date +"%T")] [$test_http_code] "
  echo -e "$prefix $1"
}

function pause {
  read -p "Press ENTER to continue..."
}

# Parse arguments
while [[ $# > 0 ]]
  do
  key="$1"

  case $key in
    -d|--debug)
      debug=1
    ;;
    -d=*|--debug=*)
      debug="${i#*=}"
    ;;
    *) # Other options and arguments
    ;;
  esac
  shift
done

echo "\$test_url='$test_url'"
echo "\$login_url='$login_url'"
echo "\$user='$user'"
echo

# DEBUG
if [[ $debug != 0 ]]; then
  echo "\$data='$data'"
  echo
  echo "[DEBUG] Test connection using HEAD:"
  test_connection_debug
  echo
  echo "[DEBUG] Forcefully logging in:"
  login_debug
  echo
fi

while :; do
  test_http_code=$(test_connection)
  
  # DEBUG
  if [[ $debug != 0 ]]; then
    echo "test_http_code='$test_http_code'"
  fi
  
  if [[ $sleep_time != $sleep_time_default ]]; then
    sleep_time=$sleep_time_default
  fi
  
  if [[ $test_http_code == 200 ]]; then
  status=$status_connected
    if [[ $last_status != $status ]]; then
      print_status "${color_green}Connected.${color_end}"
    fi
  elif [[ $test_http_code == 302 ]]; then
    if [[ $last_status != $status_logging_in ]]; then
      status=$status_logging_in
      print_status "${color_yellow}Logging in...${color_end}"
      login_http_code=$(login)
      sleep_time=$sleep_time_login
    else
      status=$status_login_failed
      print_status "${color_red}Login failed!${color_end}"
      sleep_time=$sleep_time_login_failed
    fi
  elif [[ $test_http_code == 000 ]]; then
    status=$status_no_con
    if [[ $last_status != $status ]]; then
      print_status "No connection."
      sleep_time=$sleep_time_no_con
    fi
  else
    status=$status_unknown
    if [[ $last_status != $status ]]; then
      print_status "${color_red}Unknown code.${color_end}"
    fi
  fi
  
  last_status=$status
  
  sleep $sleep_time
done

# DEBUG
if [[ $debug != 0 ]]; then
    pause
fi
