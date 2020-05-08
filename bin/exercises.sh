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

function usage {
   echo "Usage: $MYNAME [-p] [pattern]"
   echo ""
   echo "  -p       list exercises from the past"
   echo "  pattern  username or fragment of a username to list exercises for"
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
  fi
  if [ "$1" = "-p" ] ; then
    URLADDON='?filter%5Bstatus%5D=past'
  fi
  shift
  PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
done

PATTERN=${1}
PROFILE=$(ls ~/.session.*${PATTERN}*|head -1)

if [ -z "$PROFILE" ] ; then
  echo "Error: No active session found. Did you issue 'create session'?"
  exit
fi

BACKEND=$(cat $PROFILE)
PROFILE=$(basename $PROFILE)
USERNAME=$(echo ${PROFILE#.session.})
echo "Exercises for $USERNAME@$BACKEND"

SESSIONCHECK=$(curl -b ~/.iserv.$USERNAME $BACKEND/exercise 2> /dev/null|grep 'Redirecting.to.*.login')
if [ ! -z "$SESSIONCHECK" ] ; then
  echo "Error: Session expired."
  exit
fi

URL=$BACKEND/exercise$URLADDON
curl -b ~/.iserv.$USERNAME $URL 2> /dev/null|grep https|grep exercise.show | \
      sed -e 's/^.*exercise.show.\([0-9]*\)\"./\1 /g'|sed -e 's/..a...td.*$//g'
