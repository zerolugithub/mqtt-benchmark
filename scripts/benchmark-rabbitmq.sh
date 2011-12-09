#!/bin/bash
#
# This shell script automates running the stomp-benchmark [1] against the
# RabbitMQ project [2].
#
# [1]: http://github.com/chirino/stomp-benchmark
# [2]: http://www.rabbitmq.com/
#
true \
${RABBITMQ_VERSION:=2.7.0} \
${RABBITMQ_DOWNLOAD:="http://www.rabbitmq.com/releases/rabbitmq-server/v${RABBITMQ_VERSION}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz"} \
${REPORTS_HOME:=$1} \
${REPORTS_HOME:=`pwd`/report} \
${WORKSPACE:=$2} \
${WORKSPACE:=`pwd`/workspace}

. `dirname "$0"`/benchmark-setup.sh

which erl > /dev/null
if [ $? -ne 0 ] ; then
  cd "${WORKSPACE}"
  sudo yum install -y erlang
  
  which erl > /dev/null
  if [ $? -ne 0 ] ; then
    sudo yum -y install make gcc gcc-c++ kernel-devel m4 ncurses-devel openssl-devel
    wget http://www.erlang.org/download/otp_src_R14B04.tar.gz
    tar -zxvf otp_src_R14B04.tar.gz
    cd otp_src_R14B04
    rm otp_src_R14B04.tar.gz
    ./configure --with-ssl
    sudo make install
  fi
fi 

#
# Install the distro
#
RABBITMQ_HOME="${WORKSPACE}/rabbitmq_server-${RABBITMQ_VERSION}"
if [ ! -d "${RABBITMQ_HOME}" ]; then
  cd ${WORKSPACE}
  wget "$RABBITMQ_DOWNLOAD"
  tar -zxvf rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz
  rm -rf rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.gz
fi

RABBITMQ_BASE="${WORKSPACE}/rabbitmq-${RABBITMQ_VERSION}"
mkdir -p "${RABBITMQ_BASE}"

#
# Cleanup preious executions.
killall -9 java erl epmd apollo > /dev/null 2>&1
rm -rf "${RABBITMQ_BASE}/*"

#
# Rabbit config
export RABBITMQ_NODENAME=rabbit
export RABBITMQ_SERVER_ERL_ARGS=
export RABBITMQ_CONFIG_FILE="${RABBITMQ_BASE}/config"
export RABBITMQ_LOG_BASE="${RABBITMQ_BASE}/logs"
export RABBITMQ_MNESIA_BASE="${RABBITMQ_BASE}/mnesia"
export RABBITMQ_ENABLED_PLUGINS_FILE="${RABBITMQ_BASE}/plugins"
export RABBITMQ_SERVER_START_ARGS=

#
# Start the server
#s
CONSOLE_LOG="${REPORTS_HOME}/rabbitmq-${RABBITMQ_VERSION}.log"
"${RABBITMQ_HOME}/sbin/rabbitmq-plugins" enable rabbitmq_stomp
"${RABBITMQ_HOME}/sbin/rabbitmq-server" > "${CONSOLE_LOG}" 2>&1 &
RABBITMQ_PID=$!
echo "Started RabbitMQ with PID: ${RABBITMQ_PID}"
sleep 5
cat "${CONSOLE_LOG}"

#
# Run the benchmark
#
cd ${WORKSPACE}/stomp-benchmark
"${WORKSPACE}/bin/sbt" run --login guest --passcode guest "${REPORTS_HOME}/rabbitmq-${RABBITMQ_VERSION}.json"

# Kill the server
kill -9 ${RABBITMQ_PID}
killall -9 epmd
