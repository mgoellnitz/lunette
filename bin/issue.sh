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
TMPFILE="/tmp/lunette.html"
GROUPLIST="/tmp/lunette.groups"
USERLIST="/tmp/lunette.users"
ANALYZE="/tmp/lunette.analyze"
UNTIS_NEXT_LESSON=$(which next-lesson.sh)
if [ -z "$UNTIS_NEXT_LESSON" ] ; then
  UNTIS_NEXT_LESSON="./next-lesson.sh"
  if [ ! -x "$UNTIS_NEXT_LESSON" ] ; then
    UNTIS_NEXT_LESSON="$MYDIR/../../proposito-unitis/bin/next-lesson.sh"
  fi
fi

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
TAGNAME="$ISERV_TAG"
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
    if [ -x "$UNTIS_NEXT_LESSON" ] ; then
      UNTIS="untis"
    fi
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
    set_language "$1" "$LANGUAGE" lock
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
  message no_token
  echo ""
  usage
fi
TEACHERLOWER=$(echo $TEACHER|tr [:upper:] [:lower:])

PROFILE=$(ls ~/.iserv.*${PATTERN}*|head -1)
if [ -z "$PROFILE" ] ; then
  message no_session
  echo ""
  if [ -z "$PATTERN" ] ; then
    if [ -z "$BACKEND" ] ; then
      exit 1
    else
      PATTERN=$(text_input iServ enter_username_for "$BACKEND")
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
  if [ -z "$(uname -v|grep Darwin)" ] ; then
    FILETIME="$(stat -c %Y -- ~/.iserv.$USERNAME)"
  else
    FILETIME="$(stat -t %s -f %m -- ~/.iserv.$USERNAME)"
  fi
  SESSIONAGE="$(echo $[ $(date +%s) - $FILETIME ])"
  # echo "Session age: $[ $SESSIONAGE / 60 ]m (${SESSIONAGE}s)"
  if [ "$SESSIONAGE" -gt "7200" ] ; then
    # echo "SESSION TOO OLD"
    SESSIONCHECK="old"
  else
    curl -b ~/.iserv.$USERNAME $BACKEND/exercise/manage/exercise/add 2> /dev/null >$TMPFILE
    SESSIONCHECK=$(grep 'Redirecting.to.*.login' $TMPFILE;grep 'missing.*required.*authorization' $TMPFILE)
  fi
  if [ ! -z "$SESSIONCHECK" ] ; then
    message expired
    if [ -z "$LANGUAGE" ] ; then
      $MYDIR/createsession.sh $USERNAME $BACKEND
    else
      $MYDIR/createsession.sh -l $LANGUAGE $USERNAME $BACKEND
    fi
    curl -b ~/.iserv.$USERNAME $BACKEND/exercise/manage/exercise/add 2> /dev/null >$TMPFILE
  fi
fi
message creating_exercise_for $USERNAME $BACKEND
if [ $(cat $TMPFILE|wc -l) -eq 0 ] ; then
  SESSIONCHECK="There is no result"
else
  SESSIONCHECK=$(grep 'Redirecting.to.*.login' $TMPFILE)
fi
if [ ! -z "$SESSIONCHECK" ] ; then
  message no_login
  rm -f $TMPFILE
  exit 1
fi

GROUPLISTTAIL=$(cat $TMPFILE|wc -l)
GROUPLISTLENGTH=$GROUPLISTTAIL
if [ ! -z "$(grep -n participant[GU] $TMPFILE)" ] ; then
  GROUPLISTTAIL=$[ $(cat $TMPFILE|wc -l) - $(grep -n participantGroups $TMPFILE|cut -d ':' -f 1) ]
  GROUPLISTLENGTH=$(tail -$GROUPLISTTAIL $TMPFILE|grep -n participantUsers|cut -d ':' -f 1)
fi
tail -$GROUPLISTTAIL $TMPFILE|head -$GROUPLISTLENGTH|grep option.va|sed -e 's/.*"\(.*\)".*/\1/g' > $GROUPLIST
if [ $(cat $GROUPLIST|wc -l) -eq 0 ] ; then
  curl -b ~/.iserv.$USERNAME $BACKEND/profile/groups 2> /dev/null|grep option.value=|sed -e 's/^.*option.value="\(.*\)"/\1/g' > $GROUPLIST
fi
if [ -z "$PARTICIPANTUSER" ] && [ -z "$PARTICIPANTGROUP" ] ; then
  if [ -z "$GUI" ] ; then
    message no_participant
    echo ""
    usage
  else
    TAGNAME=$(text_input subject subject_tag "$TAGNAME")
    set_language $(echo $TAGNAME|sed -e 's/Span/Esp/g'|sed -e 's/^\([A-Za-z][A-Za-z]\).*/\1/g'|tr [:upper:] [:lower:]) $LANGUAGE

    FORM=$(text_input form_title input_form "$SCHOOL_FORM")
    if [ ! -z "$FORM" ] ; then
      TITLEPREFIX="$FORM "
    fi

    BESTFILTER=""
    FILTER="$FORM"
    COUNT=$(grep "$FILTER" $GROUPLIST|wc -l)
    if [ "$COUNT" -ne 0 ] ; then
      BESTFILTER="$FILTER"
      BESTCOUNT="$COUNT"
    fi

    if [ "$COUNT" -ne 1 ] ; then
      FILTER="$FORM[\.\-_]$TEACHERLOWER"
      COUNT=$(grep "$FILTER" $GROUPLIST|wc -l)
    else
      PARTICIPANTGROUP=$(grep "$FILTER" $GROUPLIST)
    fi

    if [ "$COUNT" -ne 1 ] ; then
      if [ "$COUNT" -gt 0 ] && [ "$COUNT" -lt "$BESTCOUNT" ] ; then
        BESTFILTER="$FILTER"
        BESTCOUNT="$COUNT"
      fi
      FILTER="$FORM.*$(date +%Y)"
      COUNT=$(grep "$FILTER" $GROUPLIST|wc -l)
    else
      PARTICIPANTGROUP=$(grep "$FILTER" $GROUPLIST)
    fi

    if [ "$COUNT" -ne 1 ] ; then
      if [ "$COUNT" -gt 0 ] && [ "$COUNT" -lt "$BESTCOUNT" ] ; then
        BESTFILTER="$FILTER"
        BESTCOUNT="$COUNT"
        fi
      FILTER="$FORM.$(date +%Y)"
      COUNT=$(grep "$FILTER" $GROUPLIST|wc -l)
    else
      PARTICIPANTGROUP=$(grep "$FILTER" $GROUPLIST)
    fi

    if [ "$COUNT" -ne 1 ] ; then
      if [ "$COUNT" -gt 0 ] && [ "$COUNT" -lt "$BESTCOUNT" ] ; then
        BESTFILTER="$FILTER"
        BESTCOUNT="$COUNT"
      fi
    else
      PARTICIPANTGROUP=$(grep "$FILTER" $GROUPLIST)
    fi
    if [ -z "$PARTICIPANTGROUP" ] ; then
      PARTICIPANTGROUP=$(list_select participants select_group group $(grep -E "$BESTFILTER" $GROUPLIST))
    fi
    # echo Group: $PARTICIPANTGROUP
    STARTDATE=$(select_date startdate 0 9)
    if [ -x "$UNTIS_NEXT_LESSON" ] ; then
      if [ $(question Untis ask_untis) ] ; then
        echo "asking Untis later..."
        UNTIS="untis"
      fi
    fi
    if [ -z "$UNTIS" ] ; then
      ENDDATE=$(select_date enddate 6 20)
    fi
    if [ -z "$FILENAME" ] ; then
      FILENAME=$(select_file exercise_file)
      EXERCISETITLE=$(basename "$FILENAME" .txt)
    fi
    EXERCISETITLE=$(text_input exercise_title exercise_hint "$EXERCISETITLE")
    XTYPE=$(list_select submission_format format_question submission_type $(message type_confirmation) $(message type_text) $(message type_files))
    if [ "$XTYPE" = "$(message type_text)" ] ; then
      TYPE="text"
    fi
    if [ "$XTYPE" = "$(message type_files)" ] ; then
      TYPE="files"
    fi
    # GROUPANDUSER=$($ZENITY --forms --title="Aufgabendatei" --add-entry="Teilnehmergruppe" --add-entry="Einzelteilnehmer")
    # PARTICIPANTGROUP
    # PARTICIPANTUSER
  fi
fi
if [ ! -f "$FILENAME" ] ; then
  if [ -z "$GUI" ] ; then
    message not_found "$FILENAME"
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

SEARCH_TOKEN=$(curl -b ~/.iserv.$USERNAME $BACKEND/file 2> /dev/null|grep -A1 search__token|tail -1|sed -e 's/^.*value="\([A-Za-z0-9_\-]*\).*$/\1/g')
# echo Search Token $SEARCH_TOKEN
for SEARCH_TERM in $(echo "$CONTENT"|grep ^file: |sed -e 's/^file://g') ; do
  # echo $SEARCH_TERM
  PARAMETERS="search[search]=$SEARCH_TERM"
  PARAMETERS="${PARAMETERS}&search[path]="
  PARAMETERS="${PARAMETERS}&search[_token]=$SEARCH_TOKEN"
  RESULT=$(curl -b ~/.iserv.$USERNAME -H "Content-type: application/x-www-form-urlencoded" -X POST -d "$PARAMETERS" $BACKEND/file_search 2> /dev/null)
  # echo "$RESULT"
  if [ "$(echo $RESULT|jq .status)" != "\"error\"" ] ; then
    REPLACEMENT=$(echo "$BACKEND$(echo $RESULT|jq '.data[]|select(.type.id == "File")|.name.link'|sed -e 's/.iserv//g'|sed -e 's/"//g')"|sed -e 's/\//\\\//g')
    # echo "$REPLACEMENT"
    CONTENT=$(echo "$CONTENT"|sed -e "s/file:$SEARCH_TERM/$REPLACEMENT/g")
  fi
done

AUTHCHECK=$(grep 'missing.*required.*authorization' $TMPFILE|wc -l)
if [ "$AUTHCHECK" -gt 0 ] ; then
  text_info iServ no_permission "$USERNAME" "$BACKEND"
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
  message subject_selection no_subject "$TAGNAME"
  echo ""
  rm -f $TMPFILE
  usage
fi

COURSE=$(echo $TAGNAME|sed -e 's/^\([A-Za-z][A-Za-z][A-Za-z]\).*/\1/g'|sed -e 's/Son//g'|sed -e 's/Org//g')
COURSELOWER=$(echo $COURSE| tr [:upper:] [:lower:])
if [ ! -z "$PARTICIPANTGROUP" ] ; then
  FILTER="$PARTICIPANTGROUP"
  if [ $(grep "$FILTER" $GROUPLIST|wc -l) -ne 1 ] ; then
    FILTER="$PARTICIPANTGROUP.*\.$(date +%Y)$"
    if [ $(grep "$FILTER" $GROUPLIST|wc -l) -ne 1 ] ; then
      FILTER="$COURSELOWER.*$PARTICIPANTGROUP.*\.$(date +%Y)$"
      if [ $(grep "$FILTER" $GROUPLIST|wc -l) -ne 1 ] ; then
        message ambigous_group
        echo ""
        grep "$FILTER" $GROUPLIST
        rm -f $TMPFILE $GROUPLIST
        exit 1
      else
        TEACHERLOWER=$(echo $TEACHER|tr [:upper:] [:lower:])
        if [ $(grep "$FILTER" $GROUPLIST|grep \\.$TEACHERLOWER\..|wc -l) -eq 0 ] ; then
          message ambigous_group
          echo ""
          grep "$PARTICIPANTGROUP.*\.$(date +%Y)$" $GROUPLIST
          rm -f $TMPFILE $GROUPLIST
          exit 1
        fi
      fi
    fi
  fi
  PARTICIPANTGROUP=$(grep "$FILTER" $GROUPLIST)
  if [ ! -z "$(echo $PARTICIPANTGROUP|grep "$(date +%Y)$")" ] ; then
    FORM="$(echo $PARTICIPANTGROUP|sed -e 's/^[a-z0-9]*\.//g'|sed -e 's/\.20[0-9][0-9]//g'|sed -e 's/\.[a-z][a-z]*//g'|sed -e 's/[a-z][a-z]*\.//g')"
    TITLEPREFIX="$FORM "
  fi
fi

if [ ! -z "$PARTICIPANTUSER" ] ; then
  grep option.va $TMPFILE |sed -e 's/.*"\(.*\)".*/\1/g'|grep -v "20[0-9][0-9]"|grep \\.|sort|uniq > $USERLIST
  if [ $(grep "$PARTICIPANTUSER" $USERLIST|wc -l) -ne 1 ] ; then
    message ambigous_person
    echo ""
    grep "$PARTICIPANTUSER" $USERLIST
    rm -f $TMPFILE $GROUPLIST $USERLIST
    exit 1
  fi
  PARTICIPANTUSER=$(grep "$PARTICIPANTUSER" $USERLIST)
fi

if [ ! -z "$UNTIS" ] ; then
  UNTIS_DIR=$(dirname $UNTIS_NEXT_LESSON)
  UNTIS_COURSE=$(echo $COURSE|sed -e 's/Nat/N/g'|sed -e 's/Sem/s-/g')
  echo $UNTIS_NEXT_LESSON -k -z -f "$FORM" -s "$UNTIS_COURSE"
  UNTIS_TIME=$($UNTIS_NEXT_LESSON -k -z -f "$FORM" -s "$UNTIS_COURSE")
  if [ $(echo "$UNTIS_TIME"|grep "^20"|wc -l) -eq 0 ] ; then
    if [ "$(echo "$UNTIS_URL"|grep ':'|wc -l)" -gt 0 ] ; then
      # timetable can be fetched silently
      $UNTIS_DIR/fetchtimetable.sh
      UNTIS_TIME=$($UNTIS_NEXT_LESSON -k -z -f "$FORM" -s "$UNTIS_COURSE")
    else
      if [ ! -z "$UNTIS_HOST" ] && [ ! -z "$UNTIS_SCHOOL" ] ; then
        if [ ! -z "$UNTIS_URL" ] ; then
          $UNTIS_DIR/fetchtimetable.sh $UNTIS_URL
        else
          $UNTIS_DIR/fetchtimetable.sh -i
        fi
        UNTIS_TIME=$($UNTIS_NEXT_LESSON -k -z -f "$FORM" -s "$UNTIS_COURSE")
      fi
    fi
  fi
  if [ "$UNTIS_TIME" = '?' ] ; then
    text_info Untis no_lesson "$UNTIS_COURSE" "$FORM"
    ENDDATE=$(select_date enddate 6 20)
  else
    if [ $(echo "$UNTIS_TIME"|grep "^20"|wc -l) -eq 0 ] ; then
      text_info Untis no_timetable
      ENDDATE=$(select_date enddate 6 20)
    else
      if [ -z "$(uname -v|grep Darwin)" ] ; then
        ENDDATE=$(date -d "TZ=\"UTC\" $UNTIS_TIME" "+%d.%m.%Y %H:%M")
      else
        ENDDATE=$(date -jf "%Y%m%d %H%M %z" "$UNTIS_TIME +0000" "+%d.%m.%Y %H:%M")
      fi
    fi
  fi
fi

TOKEN=$(grep -A1 exercise__token $TMPFILE |grep value|sed -e 's/.*value="\([0-9a-zA-Z_\-]*\).*/\1/g')
if [ ! -z "$COURSE" ] ; then
  COURSE="$COURSE "
fi
TITLE="$COURSE$TITLEPREFIX$TEACHER - $EXERCISETITLE"

if [ -z "$GUI" ] ; then
  echo "$TITLE: ($TYPE) [$TOKEN]"
  echo "$STARTDATE - $ENDDATE - $TAGNAME ($TAGS)"
  echo ""
  echo "$CONTENT"
  echo ""
  echo "Participating group: $PARTICIPANTGROUP - Single participant: $PARTICIPANTUSER"
fi

if [ -z $ISSUE ] ; then
  if [ -z "$GUI" ] ; then
    echo ""
    echo -n "Issue exercise this way? (j/n [Return])"
    read -s ISSUE
    if [ "$ISSUE" != "j" ] ; then
      ISSUE=
    fi
    echo ""
  else
    if [ "$TYPE" = "files" ] ; then
      XTYPE="$(message type_files)"
    fi
    if [ "$TYPE" = "text" ] ; then
      XTYPE="$(message type_text)"
    fi
    if [ "$TYPE" = "confirmation" ] ; then
      XTYPE="$(message type_confirmation)"
    fi
    DESCRIPTION="$(message submission_text $ENDDATE $XTYPE $STARTDATE)\n\n$(message participants): $PARTICIPANTGROUP $PARTICIPANTUSER\n\n$CONTENT\n\n$(message are_you_sure)"
    # echo "$DESCRIPTION"
    if [ $(question "$TITLE ($TAGNAME)" "$DESCRIPTION") ] ; then
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
  EXERCISE="${EXERCISE}&exercise[tags][]=$TAGS"
  EXERCISE="${EXERCISE}&exercise[uploadedTempFiles][picker][]="
  EXERCISE="${EXERCISE}&exercise[actions][submit]="
  EXERCISE="${EXERCISE}&exercise[_token]=$TOKEN"
  echo $EXERCISE > $ANALYZE
  curl -b ~/.iserv.$USERNAME -D - -H "Content-type: application/x-www-form-urlencoded" \
       -X POST -d "$EXERCISE" --data-urlencode "exercise[html]=$CONTENT" \
       $BACKEND/exercise/manage/exercise/add 2> /dev/null >> $ANALYZE
  # echo "System result URL: $DATA"
  text_info issued_title issued_text
fi
rm -f $TMPFILE $GROUPLIST $USERLIST
