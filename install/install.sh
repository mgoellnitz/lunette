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
CHECK=$((which curl;which unzip;which zenity)|wc -l)
if [ "$CHECK" -lt 3 ] ; then
  sudo apt update
  sudo apt install -yq curl unzip zenity
fi
sudo cp bin/*.sh /usr/local/bin
sudo cp linux/lunette.jpg /usr/local/lib
if [ -d ~/Schreibtisch ] ; then
  cp linux/Lunette.desktop ~/Schreibtisch
fi
if [ -d ~/Desktop ] ; then
  cp linux/Lunette.desktop ~/Desktop
fi
WINDOWS=$(uname -a|grep Microsoft)
if [ ! -z "$WINDOWS" ] && [ ! -f /usr/local/bin/zenity.exe ] ; then
  curl -Lo zenity.zip https://github.com/maravento/winzenity/raw/master/zenity.zip 2> /dev/null
  unzip zenity.zip
  sudo mv zenity.exe /usr/local/bin
  rm zenity.zip
fi
if [ ! -z "$WINDOWS" ] ; then
  ZENITY=zenity.exe
else
  ZENITY=zenity
fi
if [ -z $(which zenity|wc -l) ] ; then
  ZENITY=
fi
lunette-setup.sh
if [ -z "$ZENITY" ] ; then
  echo "Installation finished."
else
  $ZENITY --info --title="Installation" --text="Die Installation ist abgeschlossen."
fi
