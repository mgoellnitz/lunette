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
if [ -z $(which zenity|wc -l) ] ; then
  ZENITY=
fi

if [ -z "$ZENITY" ] ; then
  echo -n "Subject: "
  read ISERV_TAG
else
  PASSWORD=$($ZENITY --entry --text="Schulfach (wie das 'Tag' in iServ)" --entry-text="$ISERV_TAG" --hide-text --title="iServ"|sed -e 's/\r//g')
fi
grep -v ISERV_TAG= ~/.bashrc > brc 
mv brc ~/.bashrc
echo "export ISERV_TAG=$ISERV_TAG" >> ~/.bashrc
