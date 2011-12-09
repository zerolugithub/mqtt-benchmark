#!/bin/bash
#
# This shell script automates running the stomp-benchmark [1] against the
# Apache ActiveMQ project [2].
#
# [1]: http://github.com/chirino/stomp-benchmark
# [2]: http://activemq.apache.org
#

# Define variables if not yet set...
true \
${ACTIVEMQ_VERSION:=5.5.1} \
${ACTIVEMQ_DOWNLOAD:="http://www.apache.org/dist/activemq/apache-activemq/${ACTIVEMQ_VERSION}/apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz"} \
${REPORTS_HOME:=$1} \
${REPORTS_HOME:=`pwd`/report} \
${WORKSPACE:=$2} \
${WORKSPACE:=`pwd`/workspace}

. `dirname "$0"`/benchmark-setup.sh

#
# Install the apollo distro
#
ACTIVEMQ_HOME="${WORKSPACE}/apache-activemq-${ACTIVEMQ_VERSION}"
if [ ! -d "${ACTIVEMQ_HOME}" ]; then
  cd "${WORKSPACE}"
  wget "$ACTIVEMQ_DOWNLOAD"
  tar -zxvf apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz
  rm -rf apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz
fi


#
# Cleanup preious executions.
killall -9 java erl epmd apollo > /dev/null 2>&1
rm -rf ${ACTIVEMQ_HOME}/data/*

#
# Configuration
export ACTIVEMQ_OPTS="-Xmx4G -Xms1G -Dorg.apache.activemq.UseDedicatedTaskRunner=true -Djava.util.logging.config.file=logging.properties"

#
# Start the broker
#
CONSOLE_LOG="${REPORTS_HOME}/activemq-${ACTIVEMQ_VERSION}.log"
"${ACTIVEMQ_HOME}/bin/activemq" console "xbean:file:${ACTIVEMQ_HOME}/conf/activemq-stomp.xml" > "${CONSOLE_LOG}" 2>&1 &
ACTIVEMQ_PID=$!
echo "Started ActiveMQ with PID: ${ACTIVEMQ_PID}"
sleep 5
cat ${CONSOLE_LOG}

#
# Run the benchmark
#
cd "${WORKSPACE}/stomp-benchmark"
"${WORKSPACE}/bin/sbt" run "${REPORTS_HOME}/activemq-${ACTIVEMQ_VERSION}.json"

# Kill the broker
kill -9 ${ACTIVEMQ_PID}
