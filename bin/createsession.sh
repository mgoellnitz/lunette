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

USERNAME=${1}
BACKEND=${2:-$ISERV_BACKEND}

function usage {
   echo "Usage: $MYNAME username [backend]"
   echo ""
   echo "  username login of the user without domain name and the like"
   echo "  backend  backend in the form of a base URL including a trailing /iserv"
   echo ""
   exit
}

if [ -z "$USERNAME" ] ; then
  usage
fi

if [ -z "$BACKEND" ] ; then
   echo "Error: IServ Backend must be given as a second parameter or by environment variable ISERV_BACKEND."
   exit
fi

WINDOWS=$(uname -a|grep Microsoft)
if [ ! -z "$WINDOWS" ] ; then
  ZENITY=zenity.exe
else
  ZENITY=zenity
fi
if [ -z $(which zenity|wc -l) ] ; then
  ZENITY=
fi

if [ -z "$ZENITY" ] ; then
  echo -n "Password for $USERNAME@$BACKEND: "
  read -s PASSWORD
else
  PASSWORD=$($ZENITY --entry --text="Kennwort für $USERNAME" --entry-text="$PASSWORD" --hide-text --title="iServ - $BACKEND"|sed -e 's/\r//g')
fi

echo ""
echo Creating session for $USERNAME@$BACKEND
# curl -D - $BACKEND/login 2> /dev/null > /dev/null
rm -f ~/.iserv.$USERNAME
DATA=$(curl -c ~/.iserv.$USERNAME -H "Content-type: application/x-www-form-urlencoded" -X POST -D - \
            -d "_username=$USERNAME&_password=$PASSWORD&_remember_me=on" $BACKEND/login_check 2> /dev/null)
echo "#" >> ~/.iserv.$USERNAME
echo "# ISERV_BACKEND=$BACKEND" >> ~/.iserv.$USERNAME
# echo $DATA
