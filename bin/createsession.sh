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

function usage {
   echo "Usage: $MYNAME username [backend]"
   echo ""
   echo "  -k           use plain console version without dialogs"
   echo "  -l language  set ISO-639 language code for output messages (except this one)"
   echo "     username  login of the user without domain name and the like"
   echo "     backend   backend in the form of a base URL including a trailing /iserv"
   echo ""
   exit
}

PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
while [ "$PSTART" = "-" ] ; do
  if [ "$1" = "-h" ] ; then
    usage
    exit
  fi
  if [ "$1" = "-k" ] ; then
    GUI=
    ZENITY=
  fi
  if [ "$1" = "-l" ] ; then
    shift
    LANGUAGE=${1}
  fi
  shift
  PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
done
USERNAME=${1}
BACKEND=${2:-$ISERV_BACKEND}

if [ -z "$USERNAME" ] ; then
  usage
fi

if [ -z "$BACKEND" ] ; then
   echo "$(message no_backend)"
   exit
fi

PASSWORD=$(password_input "iServ - $BACKEND" "$(message password_for) $USERNAME@$BACKEND" "$PASSWORD")

echo $(message creating_session) $USERNAME@$BACKEND
# curl -D - $BACKEND/login 2> /dev/null > /dev/null
rm -f ~/.iserv.$USERNAME
DATA=$(curl -c ~/.iserv.$USERNAME -H "Content-type: application/x-www-form-urlencoded" -X POST -D - \
            -d "_username=$USERNAME&_password=$PASSWORD&_remember_me=on" $BACKEND/login_check 2> /dev/null)
echo "#" >> ~/.iserv.$USERNAME
echo "# ISERV_BACKEND=$BACKEND" >> ~/.iserv.$USERNAME
# echo $DATA
