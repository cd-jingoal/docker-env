#!/bin/sh

# where is this script? it is placed in "cmd" dir

export JAVA_HOME="/usr/local/jdk"

HOME_DIR=$(dirname $0)
cd "$HOME_DIR/.."
HOME_DIR=`pwd`

BASEDIR="/usr/local/account"
APPDIR="$BASEDIR/account-server"
APPTARBALL="$BASEDIR/account-server-*.tar.gz"

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

echo "download $PKG_URL ..."
wget -q --auth-no-challenge --http-user=admin --http-password=1ac1580ee60e6371a258f33277e92432 $PKG_URL || ( echo "download failed"; exit 1; )


## prepare program dir. take care: tarball name and dir names may change ##

cd "$BASEDIR" || (echo "cd $BASEDIR: failed"; exit 1;)
echo "unzip $APPTARBALL ..."


tar -zxvf $APPTARBALL  >/dev/null || (echo "unzip tar.gz file failed"; exit 1;)

if [ -e $APPDIR ]; then  
   rm -rf  $APPDIR
fi

export dir=`ls -l | grep ^d | awk '{print $9}'| grep 'account'`

echo $dir

mv $dir $APPDIR

echo "change config ..."

cp -rf $BASEDIR/cmd/cfg/*  $APPDIR/cfg/

if  [[ !  -e $BASEDIR/tmp/ ]]; then
    mkdir -p $BASEDIR/tmp/
fi

## stop & start ##

# stop account-server

PID=

function get_pid {
  # NOTE: exclude grep

  PID=`ps -ef | grep "com.jingoal.account.server.MasterServer" | grep -v grep | awk '{print $2}'`
  echo "get_pid: PID=$PID"
}

function stop {
  echo "stopping account-server ..."

  get_pid

  if [[ ! $PID ]]; then
    echo "account-server is not running. skip"
    return
  fi

  echo "kill account-server ..."
  kill $PID

  if [[ $? = 0 ]]; then
    counter=0
    while [[ $PID ]] && [[ $counter < 5 ]]; do
      sleep 1
      get_pid
      counter=$(($counter+1))
    done
  fi

  if [[ $PID ]]; then
    echo "killing account-server..., pid=$PID"
    # take care!
    kill  $PID
    sleep 3
    get_pid
    if [[ $PID ]]; then
      echo "killing account-server failed. pid=$PID"
      
    fi
  fi

  echo "done"
}


function start {
  echo "starting account-server ..."

  echo "call startMaster.sh ..."
  cd $APPDIR
  ./startMaster.sh > /dev/null &

  if [[ $? != 0 ]]; then
    error "unable to start account-server."
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
    error "startMaster.sh called, but can't find process."
  fi

  echo "done."
}

stop

sleep 3

start


echo "SUCESS."
