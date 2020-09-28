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
TMPFILE="/tmp/lunette.html"

MYNAME=`basename $0`
MYDIR=`dirname $0`
LIBDIR=$MYDIR/../share/lunette
source $LIBDIR/lib.sh

PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
while [ "$PSTART" = "-" ] ; do
  if [ "$1" = "-k" ] ; then
    GUI=
    ZENITY=
  fi
  if [ "$1" = "-l" ] ; then
    shift
    export LANGUAGE=${1}
  fi
  shift
  PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
done

PROFILE=$(ls ~/.iserv.*|tail -1)
if [ ! -z "$PROFILE" ] && [ ! -z "$GUI" ] ; then
  BACKEND=$(cat $PROFILE|grep ISERV_BACKEND|sed -e 's/#.ISERV_BACKEND=//g')
  PROFILE=$(basename $PROFILE)
  USERNAME=$(echo ${PROFILE#.iserv.})
  curl -b ~/.iserv.$USERNAME $BACKEND/exercise/manage/exercise/add 2> /dev/null >$TMPFILE
  SESSIONCHECK=$(grep 'Redirecting.to.*.login' $TMPFILE)
  TAGS=""
  if [ -z "$SESSIONCHECK" ] ; then
    for tag in $(grep option.va $TMPFILE |sed -e 's/.*"\(.*\)".*/\1/g'|grep ^[0-9]) ; do
      value=$(grep -A2 value.\"$tag\" $TMPFILE|tail -1|sed -e 's/\ *>\([A-Za-z][A-Za-z\ ]*\).*/\1/g')
      # echo "$tag: $value"
      TAGS=$(echo "${TAGS}$(echo $value|sed -e 's/\ /_/g')\n")
    done
    ISERV_TAG=$(list_select subject_selection default_subject subject_tag $(echo -e "$TAGS")|sed -e 's/_/ /g')
  else
    echo "$(message expired)"
    ISERV_TAG=$(text_input subject_selection default_subject "$ISERV_TAG")
  fi
else
  ISERV_TAG=$(text_input subject_selection default_subject "$ISERV_TAG")
fi
rm -f $TMPFILE
default "ISERV_TAG" "$ISERV_TAG"
