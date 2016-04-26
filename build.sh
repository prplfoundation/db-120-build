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
  [ -d $DIR/build ] && $( cd $DIR/build; make clean ) && cd $DIR
}

function dirclean {
  [ -d $DIR/build ] && $( cd $DIR/build; make dirclean )  && cd $DIR
}

if [ "$1" == "cc" ]; then
  [ "$2" == "clean" ] && dirclean
  cd $DIR
  git -C build pull --no-ff || git clone https://git.openwrt.org/15.05/openwrt.git build
  rm build/feeds.conf
  echo "src-link boardcoop $DIR/cc-feed"|cat - cc.feeds.conf > /tmp/out && mv /tmp/out build/feeds.conf
  rm build/.config
  cp .config build
  cd build
  scripts/feeds update
  scripts/feeds install -a
  make defconfig
  make V=s
  cd $DIR
elif [ "$1" == "dd" ]; then
 echo "crap"
elif [ "$1" == "update-cc"] ; then
  cd $DIR/build
  scripts/diffconfig.sh >> $DIR/cc.config
  cd $DIR
else
  echo "You must select cc or dd"
fi
