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
MYNAME=`basename $0`
WD=$(pwd|sed -e 's/\//\\\//g')
MYDIR=$(dirname $0|sed -e s/^\\./"$WD"/g|sed -e 's/\(^[a-zA-Z]\)/'"$WD"'\/\1/g')
LIBDIR=$MYDIR/../share/lunette
source $LIBDIR/lib.sh
TMPFILE="/tmp/lunette.html"
CSVFILE="/tmp/lunette.csv"
IDFILE="/tmp/lunette.ids"

function usage {
   echo "Usage: $MYNAME [-p] [-u pattern] [filter]"
   echo ""
   echo "  -p           list exercises from the past"
   echo "  -d           download exercises including attachments into separate directories"
   echo "  -l language  set ISO-639 language code for output messages (except this one)"
   echo "  -u pattern   username or fragment of a username to list exercises for"
   echo "     filter    sub-expression for the exercise titles to search for"
   echo ""
   echo "For the $0 command to work an active session"
   echo "for the given user must be present."
   echo ""
   exit
}

URLADDON='?filter%5Bstatus%5D=current'

PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
while [ "$PSTART" = "-" ] ; do
  if [ "$1" = "-h" ] ; then
    usage
    exit
  fi
  if [ "$1" = "-d" ] ; then
    DOWNLOAD=download
  fi
  if [ "$1" = "-l" ] ; then
    shift
    export LANGUAGE=${1}
  fi
  if [ "$1" = "-p" ] ; then
    URLADDON='?filter%5Bstatus%5D=past'
  fi
  if [ "$1" = "-u" ] ; then
    shift
    PATTERN=${1}
  fi
  shift
  PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
done
FILTER=${1:-.*}

BACKEND=$ISERV_BACKEND
PROFILE=$(ls ~/.iserv.*${PATTERN}*|head -1)
if [ -z "$PROFILE" ] ; then
  echo "$(message no_session)"
  echo ""
  if [ -z "$PATTERN" ] ; then
    if [ -z "$BACKEND" ] ; then
      exit 1
    else
      echo -n "$(message enter_username_for) $BACKEND: "
      read PATTERN
    fi
  fi
  $MYDIR/createsession.sh -k $PATTERN
  PROFILE=$(ls ~/.iserv.*${PATTERN}*|head -1)
  BACKEND=$(cat $PROFILE|grep ISERV_BACKEND|sed -e 's/#.ISERV_BACKEND=//g')
  PROFILE=$(basename $PROFILE)
  USERNAME=$(echo ${PROFILE#.iserv.})
  curl -b ~/.iserv.$USERNAME $BACKEND/exercise 2> /dev/null >$TMPFILE
else
  BACKEND=$(cat $PROFILE|grep ISERV_BACKEND|sed -e 's/#.ISERV_BACKEND=//g')
  PROFILE=$(basename $PROFILE)
  USERNAME=$(echo ${PROFILE#.iserv.})
  curl -b ~/.iserv.$USERNAME $BACKEND/exercise 2> /dev/null >$TMPFILE
  SESSIONCHECK=$(grep 'Redirecting.to.*.login' $TMPFILE)
  if [ ! -z "$SESSIONCHECK" ] ; then
    echo "$(message expired)"
    $MYDIR/createsession.sh -k $USERNAME $BACKEND
    curl -b ~/.iserv.$USERNAME $BACKEND/exercise 2> /dev/null >$TMPFILE
  fi
fi
echo "$(message exercises_for) $USERNAME@$BACKEND"
SESSIONCHECK=$(grep 'Redirecting.to.*.login' $TMPFILE)
if [ ! -z "$SESSIONCHECK" ] ; then
  echo "$(message no_login)"
  exit 1
fi

URL=$BACKEND/exercise$URLADDON
curl -b ~/.iserv.$USERNAME $URL 2> /dev/null|grep https|grep exercise.show | \
      sed -e 's/^.*exercise.show.\([0-9]*\)\"./\1 /g'|sed -e 's/..a...td.*$//g'|grep "${FILTER}" > $IDFILE

URL="$BACKEND/exercise.csv$URLADDON&sort%5Bby%5D=enddate&sort%5Bdir%5D=DESC"
curl -b ~/.iserv.$USERNAME $URL 2> /dev/null > $CSVFILE
FIRST=first
while IFS='' read -r LINE || [[ -n "$LINE" ]]; do
  # echo "Line: $LINE"
  # echo "$LINE"|sed -e 's/;\(.*\)$/\1/'
  RESPONSE=$(echo "$LINE"|sed -e 's/^\(.*\);\([^;]*\)$/\2/')
  LINE=$(echo "$LINE"|sed -e 's/^\(.*\);\([^;]*\)$/\1/')
  DONE=$(echo "$LINE"|sed -e 's/^\(.*\);\([^;]*\)$/\2/')
  LINE=$(echo "$LINE"|sed -e 's/^\(.*\);\([^;]*\)$/\1/')
  TAGS=$(echo "$LINE"|sed -e 's/^\(.*\);\([^;]*\)$/\2/')
  LINE=$(echo "$LINE"|sed -e 's/^\(.*\);\([^;]*\)$/\1/')
  ENDDATE=$(echo "$LINE"|sed -e 's/^\(.*\);\([^;]*\)$/\2/')
  LINE=$(echo "$LINE"|sed -e 's/^\(.*\);\([^;]*\)$/\1/')
  STARTDATE=$(echo "$LINE"|sed -e 's/^\(.*\);\([^;]*\)$/\2/')
  LINE=$(echo "$LINE"|sed -e 's/^\(.*\);\([^;]*\)$/\1/')
  TITLE=$(echo "$LINE"|sed -e 's/^\(.*\);\([^;]*\)$/\2/'|sed -e 's/^"//g'|sed -e 's/"$//g')
  if [ -z "$FIRST" ] ; then
    ID=$(grep "$TITLE" $IDFILE|cut -d ' ' -f 1)
    OUTPUT="$ID "
    if [ ! -z "$TAGS" ] ; then
      OUTPUT="$OUTPUT$TAGS: "
    fi
    OUTPUT="$OUTPUT$TITLE ($STARTDATE -> $ENDDATE)"
    if [ -z "$DONE" ] ; then
      OUTPUT="$OUTPUT *"
    fi
    OUTPUT="$OUTPUT $RESPONSE"
    if [ ! -z "$(echo "$OUTPUT"|grep "$FILTER")" ] ; then
      echo "$OUTPUT"
      if [ ! -z "$DOWNLOAD" ] ; then
        if [ -x $MYDIR/exercise.sh ] ; then
          FOLDER="$(echo $TITLE|sed -e 's/[\.\ ]/_/g'|sed -e 's/^\-//g'|sed -e 's/_$//g'|sed -e 's/^_//g')"
          mkdir -p $FOLDER
          (cd $FOLDER ; "$MYDIR/exercise.sh" -d $ID > $FOLDER.txt)
        fi
      fi
    fi
  else
    FIRST=
  fi
done < $CSVFILE

rm -f $TMPFILE $IDFILE $CSVFILE
