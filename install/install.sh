#!/bin/bash
#
# Copyright 2020 Martin Goellnitz
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
if [ ! -z "$(uname -v|grep Darwin)" ] ; then
  if [ -z "$(which jq)" ] ; then
    # if [ -z "$(which brew)" ] ; then
    #   bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    # fi
    if [ ! -z "$(which brew)" ] ; then
      brew install jq
    fi
  fi
  if [ -z "$(which html2text)" ] ; then
    # if [ -z "$(which brew)" ] ; then
    #   bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    # fi
    if [ ! -z "$(which brew)" ] ; then
      brew install html2text
    fi
  fi
fi
CHECK=$((which curl;which html2text;which unzip;which jq;which zenity)|wc -l)
if [ "$CHECK" -lt 5 ] ; then
  if [ "$(which apt|wc -l)" -eq 1 ] && [ -z "$(uname -v|grep Darwin)" ] ; then
    sudo apt update
    sudo apt install -yq curl html2text unzip jq zenity
  else
    if [ "$((which curl;which unzip;which jq)|wc -l)" -lt 3 ] ; then
      echo 'Please ensure that jq, unzip and curl are available from the $PATH - zenity is optional.'
    fi
  fi
fi
if [ -w /usr/local/bin/lunette-setup.sh ] ; then
  cp -p bin/*.sh /usr/local/bin
  cp -p linux/lunette.jpg /usr/local/lib
  cp -rp share/* /usr/local/share
else
  sudo cp -p bin/*.sh /usr/local/bin
  sudo cp -p linux/lunette.jpg /usr/local/lib
  sudo cp -rp share/* /usr/local/share
fi
if [ -z "$(uname -v|grep Darwin)" ] ; then
  if [ -d ~/Schreibtisch ] ; then
    cp linux/Lunette.desktop ~/Schreibtisch
  fi
  if [ -d ~/Desktop ] ; then
    cp linux/Lunette.desktop ~/Desktop
  fi
fi
MYDIR=$(dirname $BASH_SOURCE)|sed -e 's/install\///g'|sed -e 's/^.bin/\./g'
if [ -z "$MYDIR" ] ; then
  MYDIR="."
fi
LIBDIR=$MYDIR/share/lunette
source $MYDIR/share/lunette/lib.sh
PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
while [ "$PSTART" = "-" ] ; do
  if [ "$1" = "-l" ] ; then
    shift
    set_language "$1" "$LANGUAGE" lock
  fi
  shift
  PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
done
if [ ! -z "$WINDOWS" ] && [ ! -f /usr/local/bin/zenity.exe ] ; then
  curl -Lo zenity.zip https://github.com/maravento/winzenity/raw/master/zenity.zip 2> /dev/null
  unzip zenity.zip
  sudo mv zenity.exe /usr/local/bin
  rm zenity.zip
fi
if [ ! -z "$(uname -v|grep Darwin)" ] ; then
  if [ -z "$(grep source....bashrc ~/.bash_profile)" ] ; then
    echo 'if [ -s ~/.bashrc ]; then source ~/.bashrc; fi' >> ~/.bash_profile
  fi
fi
if [ -z "$ISERV_BACKEND" ] ; then
  lunette-setup.sh
  $(text_info installation installation_completed)
fi
