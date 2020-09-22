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
WINDOWS=$(uname -a|grep Microsoft)
if [ ! -z "$WINDOWS" ] ; then
  ZENITY=zenity.exe
else
  ZENITY=zenity
fi
if [ -z "$(which zenity)" ] ; then
  ZENITY=
fi

# localized message translation $1 is a message key
function message {
  if [ -z "$LANGUAGE" ] ; then
    LANGUAGE=$(echo $LANG|cut -d '_' -f 1)
    if [ -z "$LANGUAGE" ] ; then
      LANGUAGE="de"
    fi
  fi
  FILENAME=$LIBDIR/messages_$LANGUAGE.txt
  if [ ! -f "$FILENAME" ] ; then
    FILENAME=$LIBDIR/messages.txt
  fi
  
  p=$1
  if [ -z "$p" ] ; then
    p="untis"
  fi
  grep ^$p= $FILENAME|sed -e "s/^$p=\(.*\)$/\1/g"
}

# set default $1 in .bashrc to value $2
function default {
  grep -v "${1}=" ~/.bashrc > brc 
  mv brc ~/.bashrc
  echo "export ${1}=${2}" >> ~/.bashrc
}
