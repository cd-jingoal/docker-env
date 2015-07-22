#!/bin/bash

# where is this script? it is placed in "cmd" dir

export JAVA_HOME="/usr/local/jdk"

HOME_DIR=$(dirname $0)
cd "$HOME_DIR/.."
HOME_DIR=`pwd`

BASEDIR="/usr/local/tomcat_mgt_new/webapps"
APPDIR="$BASEDIR/webcd"
APPTARBALL="$BASEDIR/webcd*.war"
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

echo "change config ..."

CONFIDC=$APPDIR/WEB-INF/spring/config.properties
CONFIDCBAK=$CONFIDC.bak
cat $CONFIDC | sed 's/test1/test2/g'> $CONFIDCBAK
cat $CONFIDCBAK | sed 's/mgtsso.test2.com/mgtsso.test1.com/g'> tmp
mv  tmp $CONFIDC

echo "SUCESS."