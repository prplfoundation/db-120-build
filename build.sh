#!/bin/bash
set -x

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

function clean {
  [ -d $DIR/$1 ] && $( cd $DIR/$1; make clean ) && cd $DIR
}

function dirclean {
  [ -d $DIR/$1 ] && $( cd $DIR/$1; make dirclean )  && cd $DIR
}

function run_build {
  VERSION=$1
  GIT_REPO=$2
  [ "$3" == "clean" ] && clean $VERSION.build
  [ "$3" == "dirclean" ] && dirclean $VERSION.build
  cd $DIR
  git -C $VERSION.build pull --ff-only || git clone $GIT_REPO $VERSION.build
  rm $VERSION.build/feeds.conf
  echo "src-link boardcoop $DIR/$VERSION-feed"|cat - $VERSION.feeds.conf > /tmp/out && mv /tmp/out $VERSION.build/feeds.conf
  rm $VERSION.build/.config
  cd $VERSION.build
  scripts/feeds update
  scripts/feeds install -a
  make defconfig
  cp -f ../$VERSION.config .config
  make defconfig
  make V=s
  cd $DIR
}

function run_update {
  cd $DIR/$1.build
  scripts/diffconfig.sh > $DIR/$1.config
  cd $DIR
}

if [ "$1" == "cc" ]; then
  run_build 'cc' 'https://git.openwrt.org/15.05/openwrt.git' $2
elif [ "$1" == "dd" ]; then
 run_build 'dd' 'https://git.openwrt.org/openwrt.git' $2
elif [ "$1" == "update-cc" ] ; then
  run_update 'cc'
elif [ "$1" == "update-dd" ] ; then
  run_update 'dd'
else
  echo "You must select cc or dd"
fi
