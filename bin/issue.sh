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
TMPFILE="/tmp/lunette.html"
GROUPLIST="/tmp/lunette.groups"
USERLIST="/tmp/lunette.users"

function usage {
   echo "Usage: $MYNAME [-c] [-t] [-f] [-b begin] [-e end] [-g group] [-p user] [-m form] [-s subject] [-a abb] [-u username] filename.txt"
   echo ""
   echo "  -c               set exercise type to confirmation (default)"
   echo "  -t               set exercise type to writing some text online"
   echo "  -f               set exercise type uploading result files"
   echo "  -w               ask webuntis about start of next lesson to fill in end time"
   echo "  -b begin         start time in the format dd.mm.yyy HH:MM local time (default today 9:00)"
   echo "  -e end           end time in the format dd.mm.yyy HH:MM local time (default yesterday in a week 20:00)"
   echo "  -g group         exercise participants as a group identifier"
   echo "  -p person        exercise participants as a single user identifier"
   echo "  -m form          when dealing with single person exercises, add their form they are in here explicitly"
   echo "  -s subject       subject given as a valid tag name (default $SCHOOL_SUBJECT)"
   echo "  -a abb           teacher identification code as abbrevation (default $SCHOOL_TOKEN)"
   echo "  -u pattern       login of the user to read given exercise for"
   echo "     filename.txt  filename of the basic description file for a new exercise"
   echo ""
   echo "For the $0 command to work an active session"
   echo "for the given user must be present."
   echo ""
   exit
}

STARTDATE="$(date -d '9' "+%d.%m.%Y %H:%M")"
ENDDATE="$(date -d '+6 days 20' "+%d.%m.%Y %H:%M")"

# TYPE: confirmation|files|text
TYPE="confirmation"
TEACHER=$SCHOOL_TOKEN
TAGNAME=$SCHOOL_SUBJECT
BACKEND=$ISERV_BACKEND
TITLEPREFIX=""
FORM=""
PARTICIPANTUSER=""
PARTICIPANTGROUP=""
UNTIS=""

WINDOWS=$(uname -a|grep Microsoft)
if [ ! -z "$WINDOWS" ] ; then
  ZENITY=zenity.exe
else
  ZENITY=zenity
fi
if [ -z $(which zenity|wc -l) ] ; then
  ZENITY=
fi

PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
DOWNLOAD=false
while [ "$PSTART" = "-" ] ; do
  if [ "$1" = "-h" ] ; then
    usage
  fi
  if [ "$1" = "-c" ] ; then
    TYPE="confirmation"
  fi
  if [ "$1" = "-f" ] ; then
    TYPE="files"
  fi
  if [ "$1" = "-t" ] ; then
    TYPE="text"
  fi
  if [ "$1" = "-w" ] ; then
    UNTIS="untis"
  fi
  if [ "$1" = "-a" ] ; then
    shift
    TEACHER=${1}
  fi
  if [ "$1" = "-b" ] ; then
    shift
    STARTDATE=${1}
  fi
  if [ "$1" = "-e" ] ; then
    shift
    ENDDATE=${1}
  fi
  if [ "$1" = "-g" ] ; then
    shift
    PARTICIPANTGROUP=${1}
  fi
  if [ "$1" = "-m" ] ; then
    shift
    FORM=${1}
    TITLEPREFIX="$FORM "
  fi
  if [ "$1" = "-p" ] ; then
    shift
    PARTICIPANTUSER=${1}
  fi
  if [ "$1" = "-s" ] ; then
    shift
    TAGNAME=${1}
  fi
  if [ "$1" = "-u" ] ; then
    shift
    PATTERN=${1}
  fi
  shift
  PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
done
FILENAME=${1}
FILENAME=$(echo -E $FILENAME|sed -e 's/C:/\/mnt\/c/g')
if [ "$FILENAME" = "=/" ] ; then
  FILENAME=
fi

if [ -z "$FILENAME" ] ; then
  if [ -z "$ZENITY" ] ; then
    usage
  else
    FORM=$($ZENITY --entry --text="Klasse (für Oberstufe die Stufe)" --entry-text="$SCHOOL_FORM" --title="Aufgabendatei"|sed -e 's/\r//g')
    TITLEPREFIX="$FORM "
    PARTICIPANTGROUP=$($ZENITY --entry --text="Gruppe (Namensausschnitt)" --entry-text="$FORM" --title="Teilnehmer"|sed -e 's/\r//g')
    TAGNAME=$($ZENITY --entry --text="Bezeichnung der Fachmarkierung ('Tag')" --entry-text="$SCHOOL_SUBJECT" --title="Schulfach"|sed -e 's/\r//g')
    STARTDATE=$($ZENITY --calendar --title="Startdatum" --date-format="%d.%m.%Y 9:00"|sed -e 's/\r//g')
    UNTIS_NEXT_LESSON=$(which next-lesson.sh)
    if [ -z "$UNTIS_NEXT_LESSON" ] ; then
      UNTIS_NEXT_LESSON="./next-lesson.sh"
      if [ ! -x "$UNTIS_NEXT_LESSON" ] ; then
        UNTIS_NEXT_LESSON="$MYDIR/../../proposito-unitis/bin/next-lesson.sh"
      fi
    fi
    if [ -x "$UNTIS_NEXT_LESSON" ] ; then
      if $ZENITY --question --title="Untis" --text="Abgabezeit aus dem Untis Stundenplan aus der Startzeit der nächsten Stunde ermitteln?" --no-wrap ; then
        UNTIS="untis"
      fi
    fi
    if [ -z "$UNTIS" ] ; then
      ENDDATE=$($ZENITY --calendar --title="Enddatum" --year="$(date -d '+6 days 20' +%Y)" --month="$(date -d '+6 days 20' +%m|sed -e s/^0//g)" --day="$(date -d '+6 days 20' +%d)" --date-format="%d.%m.%Y 20:00"|sed -e 's/\r//g')
    fi
    FILENAME=$($ZENITY --file-selection --file-filter="Text|*.txt" --title="Aufgabendatei"|sed -e 's/\r//g'|sed -e 's/C:/\/mnt\/c\//g'|sed -e 's/\\/\//g')
    # GROUPANDUSER=$($ZENITY --forms --title="Aufgabendatei" --add-entry="Teilnehmergruppe" --add-entry="Einzelteilnehmer")
    # PARTICIPANTGROUP
    # PARTICIPANTUSER
  fi
fi
if [ ! -f "$FILENAME" ] ; then
  echo "File \"$FILENAME\" not found."
  echo ""
  usage
fi
if [ -z "$TEACHER" ] ; then
  echo "No teacher token issued."
  echo ""
  usage
fi

PROFILE=$(ls ~/.iserv.*${PATTERN}*|head -1)
if [ -z "$PROFILE" ] ; then
  echo "Error: No active session found. Did you issue 'create session'?"
  echo ""
  if [ -z "$PATTERN" ] ; then
    if [ -z "$BACKEND" ] ; then
      exit 1
    else
      echo -n "Enter $BACKEND user name: "
      read PATTERN
    fi
  fi
  $MYDIR/createsession.sh $PATTERN
  PROFILE=$(ls ~/.iserv.*${PATTERN}*|head -1)
  BACKEND=$(cat $PROFILE|grep ISERV_BACKEND|sed -e 's/#.ISERV_BACKEND=//g')
  PROFILE=$(basename $PROFILE)
  USERNAME=$(echo ${PROFILE#.iserv.})
  curl -b ~/.iserv.$USERNAME $BACKEND/exercise/manage/exercise/add 2> /dev/null >$TMPFILE
else
  BACKEND=$(cat $PROFILE|grep ISERV_BACKEND|sed -e 's/#.ISERV_BACKEND=//g')
  PROFILE=$(basename $PROFILE)
  USERNAME=$(echo ${PROFILE#.iserv.})
  curl -b ~/.iserv.$USERNAME $BACKEND/exercise/manage/exercise/add 2> /dev/null >$TMPFILE
  SESSIONCHECK=$(grep 'Redirecting.to.*.login' $TMPFILE)
  if [ ! -z "$SESSIONCHECK" ] ; then
    echo "Error: Session expired."
    $MYDIR/createsession.sh $USERNAME
    curl -b ~/.iserv.$USERNAME $BACKEND/exercise/manage/exercise/add 2> /dev/null >$TMPFILE
  fi
fi
echo "Creating Exercise for $USERNAME@$BACKEND"
if [ $(cat $TMPFILE|wc -l) -eq 0 ] ; then
  SESSIONCHECK="There is no result"
else
  SESSIONCHECK=$(grep 'Redirecting.to.*.login' $TMPFILE)
fi
if [ ! -z "$SESSIONCHECK" ] ; then
  echo "Not logged in."
  rm -f $TMPFILE
  exit 1
fi

AUTHCHECK=$(grep 'missing.*required.*authorization' $TMPFILE|wc -l)
if [ "$AUTHCHECK" -gt 0 ] ; then
  echo "You may not issue exercises on this system as user $USERNAME@$BACKEND."
  rm -f $TMPFILE
  exit 1
fi
TAGS=""
for tag in $(grep option.va /tmp/lunette.html |sed -e 's/.*"\(.*\)".*/\1/g'|grep ^[0-9]) ; do 
  value=$(grep -A2 value.\"$tag\" $TMPFILE|tail -1|sed -e 's/\ *>\([A-Za-z]*\).*/\1/g')
  # echo "$tag: ${value} ($TAGNAME)"
  if [ "$value" = "$TAGNAME" ] ; then
    TAGS="$tag"
  fi
done
if [ -z "$TAGS" ] ; then
  echo "No (valid) school subject given ($TAGNAME)."
  echo ""
  rm -f $TMPFILE
  usage
fi

COURSE=$(echo $TAGNAME|sed -e 's/^\([A-Za-z][A-Za-z][A-Za-z]\).*/\1/g')
COURSELOWER=$(echo $COURSE| tr [:upper:] [:lower:])
if [ ! -z "$PARTICIPANTGROUP" ] ; then
  grep option.va $TMPFILE |sed -e 's/.*"\(.*\)".*/\1/g'|grep $(date +%Y) > $GROUPLIST
  FILTER="$PARTICIPANTGROUP.*\.$(date +%Y)$"
  if [ $(grep "$FILTER" $GROUPLIST|wc -l) -ne 1 ] ; then
    FILTER="$COURSELOWER.*$PARTICIPANTGROUP.*\.$(date +%Y)$"
    if [ $(grep "$FILTER" $GROUPLIST|wc -l) -ne 1 ] ; then
      echo "Group specification does not refer to a single group. Please be more specific:"
      echo ""
      grep "$PARTICIPANTGROUP.*\.$(date +%Y)$" $GROUPLIST
      rm -f $TMPFILE $GROUPLIST
      exit 1
    else
      TEACHERLOWER=$(echo $TEACHER|tr [:upper:] [:lower:])
      # echo "$TEACHERLOWER: $PARTICIPANTGROUP|grep \\.$TEACHERLOWER\.."
      if [ $(grep "$FILTER" $GROUPLIST|grep \\.$TEACHERLOWER\..|wc -l) -eq 0 ] ; then
        echo "Group specification does not refer to a single group. Please be more specific:"
        echo ""
        grep "$PARTICIPANTGROUP.*\.$(date +%Y)$" $GROUPLIST
        rm -f $TMPFILE $GROUPLIST
        exit 1
      fi
    fi
  fi
  PARTICIPANTGROUP=$(grep "$FILTER" $GROUPLIST)
  FORM="$(echo $PARTICIPANTGROUP|sed -e 's/^[a-z0-9]*\.//g'|sed -e 's/\.20[0-9][0-9]//g'|sed -e 's/\.[a-z][a-z]*//g'|sed -e 's/[a-z][a-z]*\.//g')"
  TITLEPREFIX="$FORM "
fi

if [ ! -z "$PARTICIPANTUSER" ] ; then
  grep option.va $TMPFILE |sed -e 's/.*"\(.*\)".*/\1/g'|grep -v "20[0-9][0-9]"|grep \\.|sort|uniq > $USERLIST
  if [ $(grep "$PARTICIPANTUSER" $USERLIST|wc -l) -ne 1 ] ; then
    echo "Person specification does not refer to a single registered user. Please be more specific:"
    echo ""
    grep "$PARTICIPANTUSER" $USERLIST
    rm -f $TMPFILE $GROUPLIST $USERLIST
    exit 1
  fi
  PARTICIPANTUSER=$(grep "$PARTICIPANTUSER" $USERLIST)
fi

if [ ! -z "$UNTIS" ] ; then
  UNTIS=$(which next-lesson.sh)
  if [ -z "$UNTIS" ] ; then
    UNTIS="./next-lesson.sh"
    if [ ! -x "$UNTIS" ] ; then
      UNTIS="$MYDIR/../../proposito-unitis/bin/next-lesson.sh"
      if [ ! -x "$UNTIS" ] ; then
        echo "Untis command line tools not found."
        rm -f $TMPFILE $GROUPLIST $USERLIST
        exit 1
      fi
    fi
  fi
  # timetable can be fetch silently
  if [ ! -z "$UNTIS_URL" ] ; then
    $(dirname $UNTIS)/fetchtimetable.sh
  fi
  echo $UNTIS -z -f "$FORM" -s "$COURSE"
  UNTIS_TIME=$($UNTIS -z -f "$FORM" -s "$COURSE")
  if [ $(echo "$UNTIS_TIME"|grep "Please fetch"|wc -l) -gt 0 ] ; then
    if [ ! -z "$UNTIS_HOST" ] && [ ! -z "$UNTIS_SCHOOL" ] ; then
      $(dirname $UNTIS)/fetchtimetable.sh -i
      UNTIS_TIME=$($UNTIS -z -f "$FORM" -s "$COURSE")
    fi
  fi
  if [ $(echo "$UNTIS_TIME"|grep "Please fetch"|wc -l) -gt 0 ] ; then
    echo "WARNING: Current Untis timetable data is missing."
  else
    if [ "$UNTIS_TIME" = '?' ] ; then
      echo "WARNING: Could not find upcoming lesson for $COURSE in form $FORM in your untis timetable."
    else
      ENDDATE=$(date -d "TZ=\"UTC\" $UNTIS_TIME" "+%d.%m.%Y %H:%M")
    fi
  fi
fi

TOKEN=$(grep -A1 exercise__token $TMPFILE |grep value|sed -e 's/.*value="\([0-9a-zA-Z_\-]*\).*/\1/g')
TITLE="$COURSE $TITLEPREFIX$TEACHER - $(basename "$FILENAME" .txt)"
TEXT=$(cat "$FILENAME")

echo "$TITLE: ($TYPE) [$TOKEN]"
echo "$STARTDATE - $ENDDATE - $TAGNAME ($TAGS)"
echo ""
echo "$TEXT"
echo ""
echo "Participating group: $PARTICIPANTGROUP - Single participant: $PARTICIPANTUSER"

if [ -z $ISSUE ] ; then
  echo ""
  echo -n "Issue exercise this way? (j/n)"
  read -s ISSUE
  if [ "$ISSUE" != "j" ] ; then
    ISSUE=
  fi
  echo ""
fi

if [ ! -z "$ISSUE" ] ; then
  EXERCISE="exercise[title]=$TITLE"
  EXERCISE="${EXERCISE}&exercise[startDate]=$STARTDATE"
  EXERCISE="${EXERCISE}&exercise[endDate]=$ENDDATE"
  EXERCISE="${EXERCISE}&exercise[type]=$TYPE"
  if [ ! -z "$PARTICIPANTUSER" ] ; then
    EXERCISE="${EXERCISE}&exercise[participantUsers][]=$PARTICIPANTUSER"
  fi
  if [ ! -z "$PARTICIPANTGROUP" ] ; then
    EXERCISE="${EXERCISE}&exercise[participantGroups][]=$PARTICIPANTGROUP"
  fi
  EXERCISE="${EXERCISE}&exercise[text]=$TEXT"
  EXERCISE="${EXERCISE}&exercise[tags][]=$TAGS"
  EXERCISE="${EXERCISE}&exercise[uploadedTempFiles][picker][]="
  EXERCISE="${EXERCISE}&exercise[actions][submit]="
  EXERCISE="${EXERCISE}&exercise[_token]=$TOKEN"
  # echo $EXERCISE
  DATA=$(curl -b ~/.iserv.$USERNAME -H "Content-type: application/x-www-form-urlencoded" -X POST -D - \
              -d "$EXERCISE" $BACKEND/exercise/manage/exercise/add 2> /dev/null > /tmp/lunette.analyze|grep ^Location: /tmp/lunette.analyze |cut -d ' ' -f 2)
  # echo "$DATA" > /tmp/lunette.analyze
  # echo "Done."

  # echo "System result URL: $DATA"
fi
rm -f $TMPFILE $GROUPLIST $USERLIST
