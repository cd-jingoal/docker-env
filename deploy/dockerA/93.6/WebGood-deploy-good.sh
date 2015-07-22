#!/bin/bash

# where is this script? it is placed in "cmd" dir

export JAVA_HOME="/usr/local/jdk"

HOME_DIR=$(dirname $0)
cd "$HOME_DIR/.."
HOME_DIR=`pwd`

BASEDIR="/usr/local/tomcat_mgt_new/webapps"
APPDIR="$BASEDIR/webgood"
APPTARBALL="$BASEDIR/webgood*.war"
TOMCAT_BASEDIR="/usr/local/tomcat_mgt_new"
TOMCAT_BINDIR="$TOMCAT_BASEDIR/bin"

function checkParam {
  name=$1
  value=$2
  if [ -z $value ]; then
     echo "need param $name"
     exit 1
  fi
}

# set the url here. NOTE use '' to quote url string because it contains '$'

PKG_URL=$1

checkParam "PKG_URL" $PKG_URL

if [ -e $APPTARBALL ]; then
  rm -rf  $APPTARBALL
fi

cd $BASEDIR || (echo "cd $BASEDIR: failed"; exit 1;)

echo "download $PKG_URL ..."
wget -q --auth-no-challenge --http-user=admin --http-password=1ac1580ee60e6371a258f33277e92432 $PKG_URL || ( echo "download failed"; exit 1; )


## prepare program dir. take care: tarball name and dir names may change ##


echo "unzip $APPTARBALL ..."

if [ -e $APPDIR ]; then
  rm -rf  $APPDIR
fi

unzip $APPTARBALL -d $APPDIR >/dev/null || (echo "unzip war file failed"; exit 1;)

echo "SUCESS."

#. $HOME_DIR/cmd/tomcat.sh $TOMCAT_BINDIR 
cd $TOMCAT_BASEDIR

PID=

function get_pid {
  # NOTE: exclude grep
  PID=`ps aux | grep "$TOMCAT_BASEDIR/endorsed" | grep java | grep -v grep | awk '{print $2}'`
  echo "get_pid: PID=$PID"
}

function stop_tomcat {
  echo "stopping tomcat ..."

  get_pid

  if [[ ! $PID ]]; then
    echo "tomcat is not running. skip"
    return
  fi

  echo "call $TOMCAT_BINDIR/shutdown.sh ..."
  sh $TOMCAT_BINDIR/shutdown.sh

  echo "shutdown.sh returns: $?"

  if [[ $? = 0 ]]; then
    counter=0
    while [[ $PID ]] && [[ $counter < 5 ]]; do
      sleep 1
      get_pid
      counter=$(($counter+1))
    done
  fi

  if [[ $PID ]]; then
    echo "killing tomcat..., pid=$PID"
    # take care!
    echo "killing pid=$PID"
    kill $PID
    sleep 1
    get_pid
    if [[ $PID ]]; then
      echo "killing tomcat failed. pid=$PID"
    fi
  fi

  echo "done"
}

function start_tomcat {
  echo "starting tomcat ..."

  echo "call $TOMCAT_BINDIR/startup.sh ..."
  sh $TOMCAT_BINDIR/startup.sh

  if [[ $? != 0 ]]; then
    error "unable to start tomcat."
  fi

  counter=0
  while [[ $counter < 5 ]]; do
    sleep 1
    get_pid
    if [[ $PID ]]; then
      break
    fi
    counter=$(($counter+1))
  done
  if [[ ! $PID ]]; then
    error "startup.sh called, but can't find process."
  fi

  echo "done."
}

stop_tomcat

# note

sleep 10
 
start_tomcat

echo "SUCESS."
