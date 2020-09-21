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
MYDIR=`dirname $0`
LIBDIR=$MYDIR/../shared/lunette
source $LIBDIR/lib.sh
TMPFILE="/tmp/lunette.html"

function usage {
   echo "Usage: $MYNAME [-u username] [-d] exerciseid"
   echo ""
   echo "  -u pattern     login of the user to read given exercise for"
   echo "  -d             download exercise attachments into a subfolder"
   echo "                 named following the exercise id"
   echo "     exerciseid  iServ internal ID of the exercise"
   echo "                 as to be drawn form exercises list command"
   echo ""
   echo "For the $0 command to work an active session"
   echo "for the given user must be present."
   echo ""
   exit
}

PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
DOWNLOAD=false
while [ "$PSTART" = "-" ] ; do
  if [ "$1" = "-h" ] ; then
    usage
  fi
  if [ "$1" = "-d" ] ; then
    DOWNLOAD="true"
  fi
  if [ "$1" = "-u" ] ; then
    shift
    PATTERN=${1}
  fi
  shift
  PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
done
EXERCISE=${1}
if [ -z "$EXERCISE" ] ; then
  usage
fi

BACKEND=$ISERV_BACKEND
PROFILE=$(ls ~/.iserv.*${PATTERN}*|head -1)
if [ -z "$PROFILE" ] ; then
  echo "$(message "no_session")"
  echo ""
  if [ -z "$PATTERN" ] ; then
    if [ -z "$BACKEND" ] ; then
      exit 1
    else
      echo -n "$(message "enter_username_for") $BACKEND: "
      read PATTERN
    fi
  fi
  $MYDIR/createsession.sh $PATTERN
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
    echo "$(message "expired")"
    $MYDIR/createsession.sh $USERNAME
    curl -b ~/.iserv.$USERNAME $BACKEND/exercise 2> /dev/null >$TMPFILE
  fi
fi
echo "$(message "exercise") $EXERCISE $(message "for") $USERNAME@$BACKEND"
SESSIONCHECK=$(grep 'Redirecting.to.*.login' $TMPFILE)
if [ ! -z "$SESSIONCHECK" ] ; then
  echo "$(message "no_login")"
  exit 1
fi

curl -b ~/.iserv.$USERNAME $BACKEND/exercise/show/$EXERCISE 2> /dev/null >$TMPFILE

AUTHOR=$(cat $TMPFILE|grep -A1 Erstellt|tail -1|sed -e 's/^.*data-name."\(.*\)".*/\1/g')
TITLE=$(cat $TMPFILE|grep '<title>'|sed -e 's/<title>//g'|sed -e 's/.-.Aufgaben.*$//g')
STARTDATE=$(cat $TMPFILE|grep -A1 Starttermin|tail -1|sed -e 's/<td>//g'|sed -e 's/<.td>//g')
ENDDATE=$(cat $TMPFILE|grep -A1 Abgabetermin|tail -1|sed -e 's/<td>//g'|sed -e 's/<.td>//g')

LINE_COUNT=$(wc -l $TMPFILE|cut -d ' ' -f 1)

DESC_START_LINE=$(cat $TMPFILE|grep -n Beschreibung|cut -d ':' -f 1)
if [ -z "$DESC_START_LINE" ] ; then
  echo "$(message "no_exercise")"
  exit
fi
DESC_TAIL_COUNT=$(echo $[ $LINE_COUNT - $DESC_START_LINE ])
DESC_LINE_COUNT=$(tail -$DESC_TAIL_COUNT $TMPFILE|grep -n '<.tr'|cut -d ':' -f 1|head -1)

CORR_START_LINE=$(cat $TMPFILE|grep -n -A1 panel-body|grep ':'|tail -1|cut -d ':' -f 1)
CORR_TAIL_COUNT=$(echo $[ $LINE_COUNT - $CORR_START_LINE ])
CORR_LINE_COUNT=$(tail -$CORR_TAIL_COUNT $TMPFILE|grep -n '<.div'|head -1|cut -d ':' -f 1)

echo ""
echo -n $STARTDATE 
echo -n ' -> ' 
echo -n $ENDDATE
echo ": $TITLE ($AUTHOR)"
tail -$DESC_TAIL_COUNT $TMPFILE|head -$DESC_LINE_COUNT|sed -e 's/<br..>//g'|sed -e 's/<.td>//g'|sed -e 's/<.tr>//g'|sed -e 's/^.*<td.*>//g'
if [ $(cat $TMPFILE|grep iserv.img.default|wc -l) -ge 1 ] ; then
  echo ""
  echo "$(message "attachments"):"
  cat $TMPFILE|grep iserv.img.default|sed -e 's/^.*li.class.*a.href."\(.*\)"..img.class.*src=".*png".\(.*\)/\2/g'
  if [ "$DOWNLOAD" = "true" ] ; then
    mkdir -p $EXERCISE
    for d in $(cat $TMPFILE|grep iserv.img.default|sed -e 's/^.*li.class.*a.href.".*\(\/exercise.*\)"..img.class.*src=".*png".\(.*\)/\1/g') ; do
      FILENAME=$(cat $TMPFILE|grep iserv.img.default|grep $d|sed -e 's/^.*li.class.*a.href.".*\(\/exercise.*\)"..img.class.*src=".*png".\(.*\)/\2/g')
      # echo $BACKEND$d $EXERCISE/$FILENAME
      curl  -b ~/.iserv.$USERNAME -o "$EXERCISE/$FILENAME" $BACKEND$d 2> /dev/null
      # curl  -b ~/.iserv.$USERNAME -o $EXERCISE/$(echo $d|cut -d '/' -f 4) $BACKEND$d
    done
  fi
fi

if [ $(cat $TMPFILE|grep -n -A1 panel-body|grep ':'|wc -l) -gt 1 ] ; then
  echo ""
  echo "$(message "feedback"):"
  tail -$CORR_TAIL_COUNT $TMPFILE|head -$CORR_LINE_COUNT|sed -e 's/<br..>//g'|sed -e 's/<.td>//g'|sed -e 's/<.tr>//g'|sed -e 's/^.*<td>//g'
fi
rm -f $TMPFILE
