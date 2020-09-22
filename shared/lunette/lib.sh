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
if [ -z "$(which $ZENITY)" ] ; then
  ZENITY=
fi
GUI=
if [ ! -z "$ZENITY" ] || [ ! -z "$(uname -v|grep Darwin)" ] ; then
  GUI=gui
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
  
  if [ ! -z "$1" ] ; then
    if [ -z "$(echo "$1"|sed -e 's/[a-z][a-z_]*//g')" ] ; then
      RESULT=$(grep ^$1= $FILENAME|sed -e "s/^$1=\(.*\)$/\1/g")
    fi
  fi
  if [ -z "$RESULT" ] ; then
    RESULT=$1
  fi
  echo "$RESULT"
}

# $1 title $2 text
function text_info {
  if [ -z "$ZENITY" ] ; then
    echo "$(message "$2")"
  else
    $ZENITY --info --title="$(message "$1")" --text="$(message "$2")" --no-wrap
  fi
}

# $1 title $2 text $3 default
function text_input {
  if [ -z "$ZENITY" ] ; then
    echo -n "$(message "$2"): " 1>&2 
    read RESULT
  else
    RESULT=$($ZENITY --entry --title="$(message "$1")" --text="$(message "$2")" --entry-text="$3"|sed -e 's/\r//g')
  fi
  echo "$RESULT"
}

# $1 title $2 text $3 default
function password_input {
  if [ -z "$ZENITY" ] ; then
    echo -n "$(message "$2"): " 1>&2 
    read -s RESULT
  else
    RESULT=$($ZENITY --entry --title="$(message "$1")" --text="$(message "$2")" --entry-text="$3" --hide-text|sed -e 's/\r//g')
  fi
  echo "$RESULT"
}

# select one element from list given by $4 with title $1, text $2, and column $3 - no none GUI version available
function list_select {
  # choose from list {"$TRANSFORMED_LIST"} with prompt "'"$(message "$2")"'" default items {"Apple"}
  RESULT=$($ZENITY --list --title "$(message "$1")" --text "$(message "$2")" --column "$(message "$3")" $4|sed -e 's/\r//g'|cut -d '|' -f 1)
  echo "$RESULT"
}

# select file with title $1 - no none GUI version available
function select_file {
  # choose file with prompt "Please select an exercise file:"
  #   --> Result: alias "HD:Users:name:Documents:exercise.txt"
  $ZENITY --file-selection --file-filter="Text|*.txt" --title="$(message "$1")"|sed -e 's/\r//g'|sed -e 's/C:/\/mnt\/c\//g'|sed -e 's/\\/\//g'
}

# title $1, dayoffset $2, hour $3 - no none GUI version available
function select_date {
  if [ -z "$(uname -v|grep Darwin)" ] ; then
    DAY=$(date -d '+'"$2"' days' +%d|sed -e s/^0//g)
    MONTH=$(date -d '+'"$2"' days' +%m|sed -e s/^0//g)
    YEAR=$(date -d '+'"$2"' days' +%Y|sed -e s/^0//g)
  else
    DAY=$(date -jf "%s" $[ $(date "+%s") + (86400*$2) ] "+%d"|sed -e s/^0//g)
    MONTH=$(date -jf "%s" $[ $(date "+%s") + (86400*$2) ] "+%m"|sed -e s/^0//g)
    YEAR=$(date -jf "%s" $[ $(date "+%s") + (86400*$2) ] "+%Y"|sed -e s/^0//g)
  fi
  $ZENITY --calendar --title="$(message "$1")" --year="$YEAR" --month="$MONTH" --day="$DAY" --date-format="%d.%m.%Y $3:00"|sed -e 's/\r//g'
}

# title $1, text $2 - no none GUI version available
function question {
  $ZENITY --question --title="$(message "$1")" --text="$(message "$2")" --no-wrap
}

# title $1, contents filename $2 - no none GUI version available
function text_area {
  if [ -z "$2" ] ; then
    $ZENITY --text-info --title="$(message "$1")" --editable
  else
    $ZENITY --text-info --title="$(message "$1")" --editable --filename="$2"
  fi
}

# set default $1 in .bashrc to value $2
function default {
  grep -v "${1}=" ~/.bashrc > brc 
  mv brc ~/.bashrc
  echo "export ${1}=${2}" >> ~/.bashrc
}
