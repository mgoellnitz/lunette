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
else
  if [ $($ZENITY --help 2>&1|grep Unable|wc -l) -eq 1 ] ; then
    ZENITY=
  fi
fi
GUI=
if [ ! -z "$ZENITY" ] || [ ! -z "$(uname -v|grep Darwin)" ] ; then
  GUI=gui
fi

DONE=
for l in $(echo "$LANGUAGE"|sed -e 's/_[a-zA-Z][a-zA-Z]//g'|sed -e 's/:/ /g') ; do
  FILENAME=$LIBDIR/messages_$l.txt
  if [ -z "$DONE" ] && [ -f "$FILENAME" ] ; then
    DONE=true
    LANGUAGE=$l
  fi
done
FILENAME=
DONE=

# set $1 as the language to use with an optional default $2 $3 places a lock for subsequent changes
function set_language {
  # echo "SET LANGUAGE $1 $2 $3 ($LANGUAGE_LOCK)"
  if [ -z "$LANGUAGE_LOCK" ] ; then
    if [ -f $LIBDIR/messages_$1.txt ] ; then
      LANGUAGE=$1
      if [ ! -z "$3" ] ; then
        LANGUAGE_LOCK=lock
      fi
    else
      LANGUAGE=$2
    fi
  fi
}

if [ -z "$LANGUAGE" ] ; then
  set_language "$(echo $LANG|cut -d '_' -f 1)" "de"
fi

# localized message translation $1 is a message key
function message {
  local FILENAME=$LIBDIR/messages_$LANGUAGE.txt
  if [ ! -f "$FILENAME" ] ; then
    FILENAME=$LIBDIR/messages_en.txt
  fi
  
  local RESULT=
  KEY=$1
  shift
  if [ ! -z "$KEY" ] ; then
    if [ -z "$(echo "$KEY"|sed -e 's/[a-z][a-z_]*//g')" ] ; then
      RESULT=$(grep "^$KEY\( \)\?=" $FILENAME|sed -e "s/^$KEY\ *=\ *\(.*\)$/\1/g"|sed -e 's/\\:/\:/g')
      for p in $@ ; do
        RESULT=$(echo $RESULT|sed -e "s/{}/$(echo $p|sed -e 's/\//\\\//g')/")
      done
    fi
  fi
  if [ -z "$RESULT" ] ; then
    RESULT=$KEY
  fi
  echo "$RESULT"
}

# $1 title $2 text
function text_info {
  local TITLE=$1
  shift
  local TEXT=$1
  shift
  if [ -z "$GUI" ] ; then
    echo "$(message "$TEXT" $@)"
  else
    if [ -x "$(which osascript)" ] ; then
      osascript -e 'display dialog "'"$(message "$TEXT" $@)"'" with icon note buttons {"'"$(message button_ok)"'"} default button "'"$(message button_ok)"'"'|sed -e 's/button.returned:'"$(message button_ok)"'//g'
    else
      $ZENITY --info --title="$(message "$TITLE")" --text="$(message "$TEXT" $@)" --no-wrap
    fi
  fi
}

# $1 title $2 text $3 default
function text_input {
  local TITLE=$1
  shift
  local TEXT=$1
  shift
  if [ -z "$GUI" ] ; then
    echo -n "$(message "$TEXT"): " 1>&2
    read RESULT
  else
    if [ -x "$(which osascript)" ] ; then
      RESULT=$(osascript -e 'display dialog "'"$(message "$TEXT")"'" default answer "'"$@"'" with icon note buttons {"'"$(message button_ok)"'"} default button "'"$(message button_ok)"'"'|sed -e 's/^.*text.returned:\(.*\)$/\1/g')
    else
      RESULT=$($ZENITY --entry --title="$(message "$TITLE")" --text="$(message "$TEXT")" --entry-text="$@"|sed -e 's/\r//g')
    fi
  fi
  echo "$RESULT"
}

# $1 title $2 text $3 default
function password_input {
  if [ -z "$GUI" ] ; then
    echo -n "$(message "$2"): " 1>&2
    read -s RESULT
  else
    if [ -x "$(which osascript)" ] ; then
      RESULT=$(osascript -e 'display dialog "'"$(message "$2")"'" default answer "'"$3"'" with icon note buttons {"'"$(message button_ok)"'"} default button "'"$(message button_ok)"'" with hidden answer'|sed -e 's/^.*text.returned:\(.*\)$/\1/g')
    else
      RESULT=$($ZENITY --entry --title="$(message "$1")" --text="$(message "$2")" --entry-text="$3" --hide-text|sed -e 's/\r//g')
    fi
  fi
  echo "$RESULT"
}

# select one element from list given by $@ with title $1, text $2, and column $3 - no none GUI version available
function list_select {
  local TITLE=$1
  shift
  local TEXT=$1
  shift
  local COLUMN=$1
  shift
  if [ -x "$(which osascript)" ] ; then
    RESULT=$(osascript -e 'choose from list {"'$(echo "$@"|sed -e 's/ /","/g')'"} with prompt "'"$(message "$TEXT")"'"'|sed -e 's/^.*text.returned:\(.*\)$/\1/g')
  else
    RESULT=$($ZENITY --list --title "$(message "$TITLE")" --text "$(message "$TEXT")" --column "$(message "$COLUMN")" $@|sed -e 's/\r//g'|cut -d '|' -f 1)
  fi
  echo "$RESULT"
}

# select file with title $1 - no none GUI version available
function select_file {
  if [ -x "$(which osascript)" ] ; then
    RESULT="/$(osascript -e 'choose file with prompt "'"$1"'"' 2> /dev/null|cut -d ':' -f 2-50|sed -e 's/:/\//g')"
  else
    RESULT=$($ZENITY --file-selection --file-filter="Text|*.txt" --title="$(message "$1")"|sed -e 's/\r//g'|sed -e 's/C:/\/mnt\/c\//g'|sed -e 's/\\/\//g')
  fi
  echo "$RESULT"
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
  if [ -x "$(which osascript)" ] ; then
    text_input "$1" "$1" "$DAY.$MONTH.$YEAR $3:00"
  else
    $ZENITY --calendar --title="$(message "$1")" --year="$YEAR" --month="$MONTH" --day="$DAY" --date-format="%d.%m.%Y $3:00"|sed -e 's/\r//g'
  fi
}

# title $1, text $2 - no none GUI version available
function question {
  if [ -x "$(which osascript)" ] ; then
    osascript -e 'display dialog "'"$(message "$2")"'" with icon caution buttons {"'"$(message button_yes)"'","'"$(message button_no)"'"} default button "'"$(message button_yes)"'"'|grep "returned:$(message button_yes)"|sed -e 's/button.returned.'"$(message button_yes)"'/true/g'
  else
    if $ZENITY --question --title="$(message "$1")" --text="$(message "$2")" --no-wrap ; then
      echo "yes"
    fi
  fi
}

# title $1, contents filename $2 - no none GUI version available
function text_area {
  if [ -x "$(which osascript)" ] ; then
    if [ -z "$2" ] ; then
      osascript -e 'display dialog "'"$(message "$1")"'" default answer linefeed buttons {"'"$(message button_ok)"'"} default button "'"$(message button_ok)"'"'|sed -e 's/^.*text.returned:\(.*\)$/\1/g'
    else
      DEFAULT=$(cat "$2")
      osascript -e 'display dialog "'"$(message "$1")"'" default answer "'"$DEFAULT"'" buttons {"'"$(message button_ok)"'"} default button "'"$(message button_ok)"'"'|sed -e 's/^.*text.returned:\(.*\)$/\1/g'
    fi
  else
    if [ -z "$2" ] ; then
      $ZENITY --text-info --title="$(message "$1")" --editable
    else
      $ZENITY --text-info --title="$(message "$1")" --editable --filename="$2"
    fi
  fi
}

# set default $1 in .bashrc to value $2
function default {
  grep -v "${1}=" ~/.bashrc > brc 
  mv brc ~/.bashrc
  echo "export ${1}=\"${2}\"" >> ~/.bashrc
}
