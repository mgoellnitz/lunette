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
   echo "  -s subject       subject given as a valid tag name (default $ISERV_TAG)"
   echo "  -a abb           teacher identification code as abbrevation (default $SCHOOL_TOKEN)"
   echo "  -l language      set ISO-639 language code for output messages (except this one)"
   echo "  -k               use plain console version without dialogs"
   echo "  -u pattern       login of the user to read given exercise for"
   echo "     filename.txt  filename of the basic description file for a new exercise"
   echo ""
   exit
}

STARTDATE="$(date "+%d.%m.%Y 09:00")"
if [ -z "$(uname -v|grep Darwin)" ] ; then
  ENDDATE="$(date -d '+6 days 20' "+%d.%m.%Y %H:%M")"
else
  ENDDATE="$(date -j -f "%s" $[ $(date "+%s") + ( 86400 * 6 ) ] "+%d.%m.%Y 20:00")"
fi

# TYPE: confirmation|files|text
TYPE="confirmation"
TEACHER=$SCHOOL_TOKEN
TAGNAME=$ISERV_TAG
BACKEND=$ISERV_BACKEND
TITLEPREFIX=""
FORM=""
PARTICIPANTUSER=""
PARTICIPANTGROUP=""
UNTIS=""

PSTART=`echo $1|sed -e 's/^\(.\).*/\1/g'`
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
  if [ "$1" = "-k" ] ; then
    GUI=
    ZENITY=
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
  if [ "$1" = "-l" ] ; then
    shift
    LANGUAGE=${1}
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
FILENAME="$@"
FILENAME=$(echo -E $FILENAME|sed -e 's/___/ /g'|sed -e 's/C:/\/mnt\/c/g')
if [ "$FILENAME" = "=/" ] ; then
  FILENAME=
fi
EXERCISETITLE=$(basename "$FILENAME" .txt)

if [ -z "$TEACHER" ] ; then
  echo "$(message no_token)"
  echo ""
  usage
fi
TEACHERLOWER=$(echo $TEACHER|tr [:upper:] [:lower:])

PROFILE=$(ls ~/.iserv.*${PATTERN}*|head -1)
if [ -z "$PROFILE" ] ; then
  echo "$(message no_session)"
  echo ""
  if [ -z "$PATTERN" ] ; then
    if [ -z "$BACKEND" ] ; then
      exit 1
    else
      PATTERN=$(text_input "iServ" "$(message enter_username_for) $BACKEND")
    fi
  fi
  if [ -z "$LANGUAGE" ] ; then
    $MYDIR/createsession.sh $PATTERN
  else
    $MYDIR/createsession.sh -l $LANGUAGE $PATTERN
  fi
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
    echo "$(message expired)"
    if [ -z "$LANGUAGE" ] ; then
      $MYDIR/createsession.sh $USERNAME $BACKEND
    else
      $MYDIR/createsession.sh -l $LANGUAGE $USERNAME $BACKEND
    fi
    curl -b ~/.iserv.$USERNAME $BACKEND/exercise/manage/exercise/add 2> /dev/null >$TMPFILE
  fi
fi
echo "$(message creating_exercise_for) $USERNAME@$BACKEND"
if [ $(cat $TMPFILE|wc -l) -eq 0 ] ; then
  SESSIONCHECK="There is no result"
else
  SESSIONCHECK=$(grep 'Redirecting.to.*.login' $TMPFILE)
fi
if [ ! -z "$SESSIONCHECK" ] ; then
  echo "$(message no_login)"
  rm -f $TMPFILE
  exit 1
fi

grep option.va $TMPFILE |sed -e 's/.*"\(.*\)".*/\1/g'|grep $(date +%Y) > $GROUPLIST
if [ -z "$PARTICIPANTUSER" ] && [ -z "$PARTICIPANTGROUP" ] ; then
  if [ -z "$ZENITY" ] ; then
    echo "$(message no_participant)"
    echo ""
    usage
  else
    FORM=$(text_input form_title input_form "$SCHOOL_FORM")
    if [ -z "$FORM" ] ; then
      exit
    fi
    TITLEPREFIX="$FORM "
    FILTER="$FORM.*\.$(date +%Y)$"
    if [ $(grep "$FILTER" $GROUPLIST|wc -l) -ne 1 ] ; then
      if [ $(grep "$FILTER" $GROUPLIST|grep "\.$TEACHERLOWER\.$(date +%Y)$"|wc -l) -ne 1 ] ; then
        if [ $(grep "$FILTER" $GROUPLIST|grep "\.$TEACHERLOWER\.$(date +%Y)$"|wc -l) -gt 1 ] ; then
          FILTER="$FORM.*$TEACHERLOWER\.$(date +%Y)$"
        else
          FILTER="$FORM\.$(date +%Y)$"
        fi
        PARTICIPANTGROUP=$($ZENITY --list --title "$(message participants)" --text "$(message select_group)" --column "$(message group)" $(grep "$FILTER" $GROUPLIST)|sed -e 's/\r//g'|cut -d '|' -f 1)
        # PARTICIPANTGROUP=$(text_input participants "Gruppe (Namensausschnitt)" "$FORM")
        # echo "$TEACHERLOWER: $PARTICIPANTGROUP|grep \\.$TEACHERLOWER\.."
      else
        PARTICIPANTGROUP=$(grep "$FILTER" $GROUPLIST|grep "\.$TEACHERLOWER\.$(date +%Y)$")
      fi
    else
      PARTICIPANTGROUP=$(grep "$FILTER" $GROUPLIST)
    fi
    echo Group: $PARTICIPANTGROUP
    TAGNAME=$(text_input subject subject_tag "$TAGNAME")
    STARTDATE=$(select_date startdate 0 9)
    UNTIS_NEXT_LESSON=$(which next-lesson.sh)
    if [ -z "$UNTIS_NEXT_LESSON" ] ; then
      UNTIS_NEXT_LESSON="./next-lesson.sh"
      if [ ! -x "$UNTIS_NEXT_LESSON" ] ; then
        UNTIS_NEXT_LESSON="$MYDIR/../../proposito-unitis/bin/next-lesson.sh"
      fi
    fi
    if [ -x "$UNTIS_NEXT_LESSON" ] ; then
      if $(question Untis ask_untis) ; then
        UNTIS="untis"
      fi
    fi
    if [ -z "$UNTIS" ] ; then
      ENDDATE=$(select_date startdate 6 20)
    fi
    if [ -z "$FILENAME" ] ; then
      FILENAME=$(select_file exercise_file)
      EXERCISETITLE=$(basename "$FILENAME" .txt)
    fi
    EXERCISETITLE=$(text_input exercise_title "Titel (ohne Metadaten wie Datum, Lehrkraft, Fach, Stufe oder Klasse)" "$EXERCISETITLE")
    XTYPE=$(list_select submission_format format_question submission_type "Abhaken Text Datei(en)")
    if [ "$XTYPE" = "Text" ] ; then
      TYPE="text"
    fi
    if [ "$XTYPE" = "Datei(en)" ] ; then
      TYPE="files"
    fi
    # GROUPANDUSER=$($ZENITY --forms --title="Aufgabendatei" --add-entry="Teilnehmergruppe" --add-entry="Einzelteilnehmer")
    # PARTICIPANTGROUP
    # PARTICIPANTUSER
  fi
fi
if [ ! -f "$FILENAME" ] ; then
  if [ -z "$GUI" ] ; then
    echo "$(message not_found): \"$FILENAME\""
    echo ""
    usage
  else
    CONTENT=$(text_area new_exercise)
  fi
else
  if [ -z "$GUI" ] ; then
    CONTENT="$(cat "$FILENAME")"
  else
    CONTENT=$(text_area modify_exercise "$(echo $FILENAME|sed -e 's/\/mnt\/\([a-z]\)\//\1:\//g')")
  fi
fi

AUTHCHECK=$(grep 'missing.*required.*authorization' $TMPFILE|wc -l)
if [ "$AUTHCHECK" -gt 0 ] ; then
  text_info "iServ" "$(message no_permission) $USERNAME@$BACKEND."
  rm -f $TMPFILE
  exit 1
fi
TAGS=""
for tag in $(grep option.va $TMPFILE |sed -e 's/.*"\(.*\)".*/\1/g'|grep ^[0-9]) ; do 
  value=$(grep -A2 value.\"$tag\" $TMPFILE|tail -1|sed -e 's/\ *>\([A-Za-z][A-Za-z\ ]*\).*/\1/g')
  # echo "$tag: $value ($TAGNAME)"
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
  FILTER="$PARTICIPANTGROUP"
  if [ $(grep "$FILTER" $GROUPLIST|wc -l) -ne 1 ] ; then
    FILTER="$PARTICIPANTGROUP.*\.$(date +%Y)$"
    if [ $(grep "$FILTER" $GROUPLIST|wc -l) -ne 1 ] ; then
      FILTER="$COURSELOWER.*$PARTICIPANTGROUP.*\.$(date +%Y)$"
      if [ $(grep "$FILTER" $GROUPLIST|wc -l) -ne 1 ] ; then
        echo "$(message ambigous_group)"
        echo ""
        grep "$FILTER" $GROUPLIST
        rm -f $TMPFILE $GROUPLIST
        exit 1
      else
        TEACHERLOWER=$(echo $TEACHER|tr [:upper:] [:lower:])
        if [ $(grep "$FILTER" $GROUPLIST|grep \\.$TEACHERLOWER\..|wc -l) -eq 0 ] ; then
          echo "Group specification does not refer to a single group. Please be more specific:"
          echo ""
          grep "$PARTICIPANTGROUP.*\.$(date +%Y)$" $GROUPLIST
          rm -f $TMPFILE $GROUPLIST
          exit 1
        fi
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
  # timetable can be fetched silently
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
      if [ -z "$(uname -v|grep Darwin)" ] ; then
        ENDDATE=$(date -d "TZ=\"UTC\" $UNTIS_TIME" "+%d.%m.%Y %H:%M")
      else
        ENDDATE=$(date -jf "%Y%m%d %H%M" "$(next-lesson.sh -f 11 -s Bio)" "+%d.%m.%Y %H:%M")
      fi
    fi
  fi
fi

TOKEN=$(grep -A1 exercise__token $TMPFILE |grep value|sed -e 's/.*value="\([0-9a-zA-Z_\-]*\).*/\1/g')
TITLE="$COURSE $TITLEPREFIX$TEACHER - $EXERCISETITLE"

if [ -z "$ZENITY" ] ; then
  echo "$TITLE: ($TYPE) [$TOKEN]"
  echo "$STARTDATE - $ENDDATE - $TAGNAME ($TAGS)"
  echo ""
  echo "$CONTENT"
  echo ""
  echo "Participating group: $PARTICIPANTGROUP - Single participant: $PARTICIPANTUSER"
fi

if [ -z $ISSUE ] ; then
  if [ -z "$ZENITY" ] ; then
    echo ""
    echo -n "Issue exercise this way? (j/n [Return])"
    read -s ISSUE
    if [ "$ISSUE" != "j" ] ; then
      ISSUE=
    fi
    echo ""
  else
    if [ "$TYPE" = "files" ] ; then
      XTYPE="Datei(en)"
    fi
    if [ "$TYPE" = "text" ] ; then
      XTYPE="Text"
    fi
    if [ "$TYPE" = "confirmation" ] ; then
      XTYPE="Bestätigung"
    fi
    if $ZENITY --question --title="$TITLE ($TAGNAME)" --text="Zur Abgabe $ENDDATE als \"$XTYPE\" (Start: $STARTDATE)\n\nTeilnehmer: $PARTICIPANTGROUP $PARTICIPANTUSER\n\n$CONTENT\n\nMöchten Sie die Aufgabe so stellen?" --no-wrap ; then
      ISSUE="j"
    fi
  fi
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
  EXERCISE="${EXERCISE}&exercise[text]=$CONTENT"
  EXERCISE="${EXERCISE}&exercise[tags][]=$TAGS"
  EXERCISE="${EXERCISE}&exercise[uploadedTempFiles][picker][]="
  EXERCISE="${EXERCISE}&exercise[actions][submit]="
  EXERCISE="${EXERCISE}&exercise[_token]=$TOKEN"
  # echo $EXERCISE
  DATA=$(curl -b ~/.iserv.$USERNAME -H "Content-type: application/x-www-form-urlencoded" -X POST -D - \
              -d "$EXERCISE" $BACKEND/exercise/manage/exercise/add 2> /dev/null > /tmp/lunette.analyze|grep ^Location: /tmp/lunette.analyze |cut -d ' ' -f 2)
  # echo "System result URL: $DATA"
  $(text_info issued_title issued_text)
fi
rm -f $TMPFILE $GROUPLIST $USERLIST
