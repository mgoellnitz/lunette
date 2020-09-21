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

if [ -z "$ZENITY" ] ; then
  echo -n "$(message "iserv_host"): "
  read ISERV_BACKEND
  echo -n "$(message "iserv_user"): "
  read USERNAME
  if [ ! -z "$(echo "$USERNAME"|grep "^[a-z]\.[a-z]")" ] ; then
    echo -n "$(message "school_token"): "
    read SCHOOL_TOKEN
    echo -n "$(message "default_subject"):"
    read ISERV_TAG
  fi
else  
  ISERV_BACKEND=$($ZENITY --entry --text="$(message "iserv_host")" --entry-text="$(echo $ISERV_BACKEND|sed -e 's/^https:..\(.*\).iserv$/\1/g')" --title="iServ"|sed -e 's/\r//g')
  USERNAME=$($ZENITY --entry --text="$(message "iserv_user")" --entry-text="$(ls ~/.iserv.*|head -1|sed -e 's/.*.iserv.\(.*\)$/\1/g')" --title="$ISERV_BACKEND"|sed -e 's/\r//g')
  if [ ! -z "$(echo "$USERNAME"|grep "^[a-z]\.[a-z]")" ] ; then
    SCHOOL_TOKEN=$($ZENITY --entry --text="$(message "school_token")" --entry-text="$SCHOOL_TOKEN" --title="$(message "school")"|sed -e 's/\r//g')
    ISERV_TAG=$($ZENITY --entry --text="$(message "default_subject")" --entry-text="$ISERV_TAG" --title="$(message "subject_selection")"|sed -e 's/\r//g')
  fi
fi

default "ISERV_BACKEND" "https://$ISERV_BACKEND/iserv"
default "ISERV_TAG" "$ISERV_TAG"
default "SCHOOL_TOKEN" "$SCHOOL_TOKEN"
echo "# ISERV_BACKEND=https://$ISERV_BACKEND/iserv" > ~/.iserv.$USERNAME
