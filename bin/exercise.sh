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
TMPFILE="/tmp/lunette.html"

function usage {
   echo "Usage: $MYNAME -u username exerciseid"
   echo ""
   echo "  -u pattern     login of the user to read given exercise for"
   echo "     exerciseid  iServ internal ID of the exercise"
   echo "                 as to be drawn form exercises list command"
   echo ""
   echo "For the $0 command to work an active session"
   echo "for the given user must be present."
   echo ""
   exit
}

PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
while [ "$PSTART" = "-" ] ; do
  if [ "$1" = "-h" ] ; then
    usage
  fi
  if [ "$1" = "-u" ] ; then
    shift
    PATTERN=${1}
  fi
  shift
  PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
done

PROFILE=$(ls ~/.session.*${PATTERN}*|head -1)
if [ -z "$PROFILE" ] ; then
  echo "Error: No active session found. Did you issue 'create session'?"
  exit
fi

BACKEND=$(cat $PROFILE)
PROFILE=$(basename $PROFILE)
USERNAME=$(echo ${PROFILE#.session.})
EXERCISE=${1}
if [ -z "$EXERCISE" ] ; then
  usage
fi

echo "Exercise $EXERCISE for $USERNAME@$BACKEND"
curl -b ~/.iserv.$USERNAME $BACKEND/exercise/show/$EXERCISE 2> /dev/null >$TMPFILE

TITLE=$(cat $TMPFILE|grep '<title>'|sed -e 's/<title>//g'|sed -e 's/.-.Aufgaben.*$//g')
STARTDATE=$(cat $TMPFILE|grep -A1 Starttermin|tail -1|sed -e 's/<td>//g'|sed -e 's/<.td>//g')
ENDDATE=$(cat $TMPFILE|grep -A1 Abgabetermin|tail -1|sed -e 's/<td>//g'|sed -e 's/<.td>//g')

LINE_COUNT=$(wc -l $TMPFILE|cut -d ' ' -f 1)
DESC_START_LINE=$(cat $TMPFILE|grep -n Beschreibung|cut -d ':' -f 1)
TAIL_COUNT=$(echo $[ $LINE_COUNT - $DESC_START_LINE ])
DESC_LINE_COUNT=$(tail -$TAIL_COUNT $TMPFILE|grep -n '<.tr'|cut -d ':' -f 1|head -1)

echo -n $STARTDATE 
echo -n ' -> ' 
echo -n $ENDDATE
echo ": $TITLE"
echo ""
tail -$TAIL_COUNT $TMPFILE|head -$DESC_LINE_COUNT|sed -e 's/<br..>//g'|sed -e 's/<.td>//g'|sed -e 's/<.tr>//g'|sed -e 's/^.*<td>//g'

# rm $TMPFILE