#!/usr/bin/env bash

# exit if meet any error
set -e

bin=`dirname "${BASH_SOURCE-$0}"`
APP_HOME=`cd "$bin"/..;pwd`
PRG_NAME=class_name

# set java option
JAVA_OPTS="${JAVA_OPTS} -Xms1024m -Xmx1024m"

# export config center address
#if [ -z "${SPRING_PROFILES_ACTIVE}" ];then
#  echo "Error: SPRING_PROFILES_ACTIVE is not set, must be dev, uat"
#  exit 1
#fi

# read environment parameter and export, for easy debug usage
# CONF_ENV_FILE="$APP_HOME/bin/config-${SPRING_PROFILES_ACTIVE}.env"
# source "$CONF_ENV_FILE"

function print_usage()
{
  echo " "
  echo "Usage: $PRG_NAME [parameters]"
  echo "Required parameter is one of:"
  echo "  start     start $PRG_NAME"
  echo "  stop      stop  $PRG_NAME"
  echo "  restart   restart $PRG_NAME"
  echo "  status    show status of $PRG_NAME"
  echo "   "
  echo ""
}

if [ $# = 0 ];then
  print_usage
  exit
fi

# auto find the executeable jar with version
function get_mainjar()
{
  for jar in "$APP_HOME"/*.jar
  do
    PRG_NAME=${jar}
  done
  echo "PRG_NAME: $PRG_NAME"
}


# scan jar lib under given directories and append to classpath
function load_classpath()
{
  CLASSPATH="$APP_HOME"/config/
  for jar in "$APP_HOME"/lib/*.jar
  do
    CLASSPATH=${CLASSPATH}:${jar}
  done

  for jar in "$APP_HOME"/target/*.jar
  do
    CLASSPATH=${CLASSPATH}:${jar}
  done

  for jar in "$APP_HOME"/target/lib/*.jar
  do
    CLASSPATH=${CLASSPATH}:${jar}
  done
}

function load_java()
{
  get_mainjar

  #some java parameters
  if [ "$JAVA_HOME" != "" ];then
    # echo "run java in $JAVA_HOME"
    JAVA_HOME=$JAVA_HOME
  else
    JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")
  fi

  if [ "$JAVA_HOME" = "" ];then
    echo "Error: JAVA_HOME is not set."
    exit 1
  fi

  load_classpath

  #print out evn properties
  echo \$JAVA_HOME=$JAVA_HOME
  echo \$APP_HOME=$APP_HOME
  echo \$SERVER_PORT=$SERVER_PORT
  echo \$JAVA_OPTS="${JAVA_OPTS}"
  echo \$PRG_NAME=$PRG_NAME

}


function start()
{
  load_java

  RUNNING=`ps -ef|grep $PRG_NAME|grep -v grep|awk '{print $2}'`
  if [ -n "$RUNNING" ];then
    echo "$PRG_NAME is running! $RUNNING"
  else
    echo "starting $PRG_NAME ..."
    echo "nohup $JAVA_HOME/bin/java $JAVA_OPTS -jar $PRG_NAME --spring.config.location=$APP_HOME/config/ --logging.config=$APP_HOME/config/logback-spring.xml &"
    exec nohup $JAVA_HOME/bin/java $JAVA_OPTS -jar $PRG_NAME --spring.config.location=$APP_HOME/config/ --logging.config=$APP_HOME/config/logback-spring.xml &

    sleep 4s
    if [ $? -eq 0 ]; then
      echo "$PRG_NAME started success. "
    else
      echo "$PRG_NAME started failed! "
      exit 1
    fi
  fi
}

function status()
{
  load_java
  echo "check $PRG_NAME status..."
  RUNNING=`ps -ef|grep $PRG_NAME|grep -v grep|awk '{print $2}'`
  if [ -n "$RUNNING" ];then
    processid=`pgrep -f "$PRG_NAME"`
    echo "$PRG_NAME is running as processid: $processid"
  else
    echo "$PRG_NAME is not running."
  fi
}

function stop()
{
  load_java

  echo "stopping $PRG_NAME..."
  pkill -f "$PRG_NAME"
  echo "$PRG_NAME is stopped!"
}


case "$1" in
  --help|-help|-h)
    print_usage
    exit
    ;;
  status)
    status
    ;;
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    sleep 3s
    start
    ;;
  *)
esac
exit $?;


