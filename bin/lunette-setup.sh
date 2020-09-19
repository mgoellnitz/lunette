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
if [ -z "$(which zenity)" ] ; then
  ZENITY=
fi

if [ -z "$ZENITY" ] ; then
  echo -n "iServ Host: "
  read ISERV_BACKEND
  echo -n "iServ Username: "
  read USERNAME
  echo -n "Your Token: "
  read SCHOOL_TOKEN
else  
  ISERV_BACKEND=$($ZENITY --entry --text="iServer Hostname" --entry-text="$(echo $ISERV_BACKEND|sed -e 's/^https:..\(.*\).iserv$/\1/g')" --title="iServ"|sed -e 's/\r//g')
  USERNAME=$($ZENITY --entry --text="iServer Benutzername" --entry-text="$(ls ~/.iserv.*|head -1|sed -e 's/.*.iserv.\(.*\)$/\1/g')" --title="iServ"|sed -e 's/\r//g')
  SCHOOL_TOKEN=$($ZENITY --entry --text="Kürzel" --entry-text="$SCHOOL_TOKEN" --title="Schule"|sed -e 's/\r//g')
fi

grep -v ISERV_BACKEND= ~/.bashrc > brc 
mv brc ~/.bashrc
echo "export ISERV_BACKEND=https://$ISERV_BACKEND/iserv" >> ~/.bashrc
grep -v SCHOOL_TOKEN= ~/.bashrc > brc 
mv brc ~/.bashrc
echo "export SCHOOL_TOKEN=$SCHOOL_TOKEN" >> ~/.bashrc
echo "# ISERV_BACKEND=https://$ISERV_BACKEND/iserv" > ~/.iserv.$USERNAME
