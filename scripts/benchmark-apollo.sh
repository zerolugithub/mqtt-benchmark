#!/bin/bash
#
# This shell script automates running the stomp-benchmark [1] against the
# Apache Apollo project [2].
#
# [1]: http://github.com/chirino/stomp-benchmark
# [2]: http://activemq.apache.org/apollo
#

true \
${APOLLO_VERSION:=1.0-beta6} \
${APOLLO_DOWNLOAD:='https://repository.apache.org/content/repositories/orgapacheactivemq-299/org/apache/activemq/apache-apollo/1.0-beta6/apache-apollo-1.0-beta6-unix-distro.tar.gz'} \
${REPORTS_HOME:=$1} \
${REPORTS_HOME:=`pwd`/report} \
${WORKSPACE:=$2} \
${WORKSPACE:=`pwd`/workspace}

. `dirname "$0"`/benchmark-setup.sh

#
# Install the apollo distro
#
APOLLO_HOME="${WORKSPACE}/apache-apollo-${APOLLO_VERSION}"
if [ ! -d "${APOLLO_HOME}" ]; then
  cd ${WORKSPACE}
  wget "$APOLLO_DOWNLOAD"
  tar -zxvf apache-apollo-*.tar.gz
  rm -rf apache-apollo-*.tar.gz
fi

APOLLO_BASE="${WORKSPACE}/apollo-${APOLLO_VERSION}"
if [ ! -d "${APOLLO_BASE}" ]; then
  cd "${WORKSPACE}"
  "${APOLLO_HOME}/bin/apollo" create "apollo-${APOLLO_VERSION}"
fi

#
# Cleanup preious executions.
killall -9 java erl epmd apollo > /dev/null 2>&1
rm -rf ${APOLLO_BASE}/data/* ${APOLLO_BASE}/tmp/* ${APOLLO_BASE}/log/*

#
# Configuration
export JVM_FLAGS="-server -Xmx4G -Xms1G"

#
# Start the server
CONSOLE_LOG="${REPORTS_HOME}/apollo-${APOLLO_VERSION}.json"
"${APOLLO_BASE}/bin/apollo-broker" run > "$CONSOLE_LOG}" 2>&1 &
APOLLO_PID=$!
echo "Started Apollo with PID: ${APOLLO_PID}"
sleep 5
cat "${CONSOLE_LOG}"

#
# Run the benchmark
cd ${WORKSPACE}/stomp-benchmark
"${WORKSPACE}/bin/sbt" run --login admin --passcode password "${REPORTS_HOME}/apollo-${APOLLO_VERSION}.json"

#
# Kill the server
kill -9 ${APOLLO_PID}
