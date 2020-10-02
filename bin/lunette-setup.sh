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

ISERV_BACKEND=$(text_input iServ iserv_host "$(echo $ISERV_BACKEND|sed -e 's/^https:..\(.*\).iserv$/\1/g')")
USERNAME=$(text_input "$ISERV_BACKEND" iserv_user "$(ls ~/.iserv.*|head -1|sed -e 's/.*.iserv.\(.*\)$/\1/g')")
# This is a highly school specific pattern to tell teachers and students apart
if [ ! -z "$(echo "$USERNAME"|grep "^[a-z]\.[a-z]")" ] ; then
  SCHOOL_TOKEN=$(text_input school school_token "$SCHOOL_TOKEN")
  ISERV_TAG=$(text_input subject_selection default_subject "$ISERV_TAG")
fi

default "ISERV_BACKEND" "https://$ISERV_BACKEND/iserv"
default "ISERV_TAG" "$ISERV_TAG"
default "SCHOOL_TOKEN" "$SCHOOL_TOKEN"
if [ ! -z "$USERNAME" ] ; then
  echo "# ISERV_BACKEND=https://$ISERV_BACKEND/iserv" > ~/.iserv.$USERNAME
fi
