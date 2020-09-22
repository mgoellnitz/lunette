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

# include test "framework"
MYDIR=`dirname $0`
source $MYDIR/shelltest.sh

# setup test
before

mkdir -p .hg
mkdir -p .git

# test session creation
export ISERV_BACKEND=
OUTPUT=$($CWD/bin/createsession.sh|head -1)
# echo "$OUTPUT"
assertEquals "Unexpected session creation output" "$OUTPUT" "Usage: createsession.sh username [backend]"

OUTPUT=$($CWD/bin/createsession.sh -l en rainer.hohn|tail -1)
# echo "$OUTPUT"
assertEquals "Unexpected session creation output" "$OUTPUT" 'Error: IServ Backend must be given as a second parameter or by environment variable $ISERV_BACKEND.'

OUTPUT=$($CWD/bin/createsession.sh -l en rainer.hohn https://avh.hamburg/iserv|tail -1)
# echo "$OUTPUT"
assertEquals "5 Unexpected session creation output" "$OUTPUT" "Password for rainer.hohn@https://avh.hamburg/iserv: Creating session for rainer.hohn@https://avh.hamburg/iserv"

export ISERV_BACKEND=https://avh.hamburg/iserv
OUTPUT=$($CWD/bin/createsession.sh -l en rainer.hohn|tail -1)
# echo "$OUTPUT"
assertEquals "Unexpected session creation output" "$OUTPUT" "Password for rainer.hohn@https://avh.hamburg/iserv: Creating session for rainer.hohn@https://avh.hamburg/iserv"

# cleanup test
after
