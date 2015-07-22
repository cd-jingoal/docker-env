#!/bin/sh

# where is this script? it is placed in "cmd" dir

export JAVA_HOME="/usr/local/jdk"

HOME_DIR=$(dirname $0)
cd "$HOME_DIR/.."
HOME_DIR=`pwd`

BASEDIR="/usr/local/mgt_agent"
APPDIR="$BASEDIR/shadow-agent"
APPTARBALL="$BASEDIR/shadow-agent-*.tar.gz"
BINDIR="$APPDIR/bin"

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

if [ -e $APPDIR ]; then
  rm -rf  $APPDIR
fi

tar -zxvf $APPTARBALL >/dev/null || (echo "unzip tar.gz file failed"; exit 1;)

export dir=`ls -l | grep ^d | awk '{print $9}'| grep 'shadow'`

echo $dir

mv $dir $APPDIR

echo "change config."
# change config 
CONFIDC=$APPDIR/conf/spring/placeholder/shadow-agent-idc.properties
CONFIDCBAK=$CONFIDC.bak
cat $CONFIDC | sed 's/^idc.id=0/idc.id=1/g' | sed 's/^idc.id.other=1/idc.id.other=0/g' > $CONFIDCBAK
mv $CONFIDCBAK $CONFIDC


## stop & start ##

cd $BINDIR

# stop
./stop.sh skip || (echo "run stop.sh failed."; exit 1;)

sleep 3

# start
./start.sh || (echo "run start.sh failed."; exit 1;)

echo "SUCESS."
