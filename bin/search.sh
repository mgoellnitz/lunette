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
LIBDIR=$MYDIR/../share/lunette
source $LIBDIR/lib.sh
TMPFILE="/tmp/lunette.html"

function usage {
   echo "Usage: $MYNAME [-p] [-u pattern] [filter]"
   echo ""
   echo "  -l language  set ISO-639 language code for output messages (except this one)"
   echo "  -u pattern   username or fragment of a username to list exercises for"
   echo "     filter    sub-expression for the exercise titles to search for"
   echo ""
   echo "For the $0 command to work an active session"
   echo "for the given user must be present."
   echo ""
   exit
}

URLADDON=""

PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
while [ "$PSTART" = "-" ] ; do
  if [ "$1" = "-h" ] ; then
    usage
    exit
  fi
  if [ "$1" = "-l" ] ; then
    shift
    set_language "$1" "$LANGUAGE" lock
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
echo "$(message files_of) $USERNAME@$BACKEND"
SESSIONCHECK=$(grep 'Redirecting.to.*.login' $TMPFILE)
if [ ! -z "$SESSIONCHECK" ] ; then
  echo "$(message no_login)"
  exit 1
fi

URL=$BACKEND/file
SEARCH_TOKEN=$(curl -b ~/.iserv.$USERNAME $URL 2> /dev/null|grep -A1 search__token|tail -1|sed -e 's/^.*value="\([A-Za-z0-9_\-]*\).*$/\1/g')
# curl -b ~/.iserv.$USERNAME $URL 2> /dev/null|grep -A1 search__token|tail -1
# echo Search Token $SEARCH_TOKEN

URL=$BACKEND/file_search
PARAMETERS="search[search]=$FILTER"
PARAMETERS="${PARAMETERS}&search[path]="
PARAMETERS="${PARAMETERS}&search[_token]=$SEARCH_TOKEN"
# echo $PARAMETERS
RESULT=$(curl -b ~/.iserv.$USERNAME -H "Content-type: application/x-www-form-urlencoded" -X POST -d "$PARAMETERS" $URL 2> /dev/null)

if [ $(echo $RESULT|jq .status) = "\"error\"" ] ; then
  echo $(echo $RESULT)|jq .messages[].text
else
  if [ $(echo $RESULT|jq '.data[]|select(.type.id == "File")|.id'|wc -l) -eq 1 ] ; then
    echo "$BACKEND$(echo $RESULT|jq '.data[]|select(.type.id == "File")|.name.link'|sed -e 's/.iserv//g'|sed -e 's/"//g')"
  else
    echo $RESULT|jq '.data[]|select(.type.id == "File")|.name.text,.name.link'
  fi
fi
