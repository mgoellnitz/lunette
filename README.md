# iServ related Command Line Tools

[![License](https://img.shields.io/github/license/mgoellnitz/lunette.svg)](https://github.com/mgoellnitz/lunette/blob/master/LICENSE)
[![Build](https://img.shields.io/gitlab/pipeline/backendzeit/lunette.svg)](https://gitlab.com/backendzeit/lunette/pipelines)
[![Download](https://img.shields.io/badge/Download-Snapshot-blue)](https://gitlab.com/backendzeit/lunette/-/jobs/artifacts/master/download?job=build)

"Hacking iServ for Fun and ... whatever."

After getting past the cookie and login stuff I started to address the following
objectives with a generic collection of command line scripts:

* collecting tasks and materials for offline use in student's view
* easier handling of new exercises with automated parameter selection in teacher's view
* collecting submissions for tasks for offline use in teacher's view

The scripts are mainly used with GNU/Linux but are also partially tested with
MacOS and also Windows Systems with a `Windows Subsystem for Linux` and a Debian
distribution install from the store on top of that.

A limited GUI feeling is achived through simple dialog-to-shell tools
(`zenity`) for GNU/Linux, Windows, and OS X (via `AppleScript`).


## Feedback

This repository is available at [github][github] and [gitlab][gitlab]. Please 
prefer the [issues][issues] section of this repository at [gitlab][gitlab]
for feedback.


## Naming

While for any generic usage with [iServ][iserv] the origin of the name might be
mysterious, it translates very well:

lunette: telescope, Fr.

The real origin of the name is the acronym of an acronym for a given instance
of [iServ][iserv] with just `te` appended to sound a bit french.


## Windows Integration

The use of this tool with windows is possible but limited to systems where the
Windows Subsystem for Linux (WSL) is installed and a linux distribution 
`Debian` or `Ubuntu` is installed from the Store.


## Installation

Besides the usual manual mode if extracting the files from the distribution
archive to a place of your chosing and add this to you PATH-variable, a short
version for inexperiences users is presented especially on Windows (WSL)
systems.

After downloading and extracting the archive 

### On Windows Systems 

Double click `install.bat`. When asked for a password, use the one given for 
the `WSL` user. Also answer the questions about the backend system in use.

### On Linux and MacOS Systems

call `./install.sh` in the top level directory and answer the questions.

(This installation method is not meant to be the most elegant way.)

### Blind Installation

The afforementioned way is also implemented as a script to be directly 
downloaded and called by issuing

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/mgoellnitz/lunette/master/blind-install.sh)"
```


## Language Switch

All messages except the help lists for the commands (`-h` switch) are available
in a set of prepared languages. Thus you may select the language used 
independently of your operatign system - perhaps according to the school 
subject you are using at a given time.


## Dialog based Usage

The basic usage to create new exercises can be used as a guided sequence of
simple dialogs to focus only on the few inputs really necessary for consistent
exercised parameters and content.

Dialogs are opened wherever the system environment allows this. You may use
the `-k` switch for most commands to force console usage.

### On Linux Systems

After the installation step, which is done on the command line, you will find a
"New Exercise" icon on your desktop. With a double-click on this icon you start
the creation process.

### On Windows Systems

The windows subfolder of the installation contains clickable starters to

* issue a new exercise based on a prepared text file.
* switch the context of the subject you are currently working on
* setup basic values (also done during installation)

### On OS XSystems

After the installation step you should close the terminal. In any new terminal
session the exercise creation process is started with the command `issue.sh`.


## Command Line Usage in Student's View

For each and every tasks [iServ][iserv] needs a valid session. To avoid 
repeated login, we maintain sessions through cookie-collection files. 
Additionally this tool is multi session capable, holding more than one 
session at a time. Timeout of sessions usually is observed to be 24h.


* Create a new Session

```
./createsession.sh user.name [backend]
```

Creates a new session for the given user. 

```
$ ./createsession.sh rainer.hohn https://mdg-ni.de/iserv
Password for rainer.hohn@https://mdg-ni.de/iserv:
```

If no backend is issued, the contents
of the environent variable `ISERV_BACKEND` are taken into account.

```
export ISERV_BACKEND=https://hansa-schule.net/iserv
```

Session creation results in two files in the home directory of the current
user: `~/.session.user.name` holding the backend to be used for the user and 
`~/.iserv.user.name` holding the cookies for the current session of that user.

* List Exercises

To list the current exercises, issue the command

```
exercises.sh [user.name]
```

Without any parameters this command would list the exercises of one random user
with a currently valid session. So, if you only have one open session, this is
sufficient. If you are working with multiple sessions in parallel, at least
portions of the username need to be given as a parameter.

```
$ exercises.sh -u claire
Exercises for claire.delune@https://bornbrook.de/iserv
```

If the list grows too big, you might want to filter for certain elements in the
title.

```
$ exercises.sh Maths
Exercises for claire.delune@https://bornbrook.de/iserv
1234 Maths 6a - Fractions
```

It is also possible to list past exercises with an optional `-p` parameter.

```
$ exercises.sh -p -u claire
Exercises for claire.delune@https://bornbrook.de/iserv
```

* Show one Exercise

To show the details of one single exercise, issue the command

```
exercise.sh exerciseid
```

with an exerciseid drawn from the exercise listing command. As with other 
commands an optional pattern can be given to select the active iServ session
to use.

```
exercise.sh -u claire exerciseid
```

To download the attachments to a local folder `exerciseid/`, add the download
option.

```
exercise.sh -d exerciseid
```

This will result in a subfolder of the current folder named `exerciseid` 
containing the files mentioned in the exercise details.


## Quickly fetch all Exercises as a local Mirror

```
for e in $(exercises.sh -p|cut -d ' ' -f 1) ; do exercise.sh -d $e > $e.txt ; done
```


## Command Line Usage in Teacher's View

For each and every tasks [iServ][iserv] needs a valid session. To avoid 
repeated login, we maintain sessions through cookie-collection files. 
Additionally this tool is multi session capable, holding more than one 
session at a time. Timeout of sessions usually is observed to be 24h.

Of couse all commands available to students are available in this view, too.

Additionally it is possible to issue new exercises with a consistent naming
scheme and reduce parameter input to avoid mistakes. Additionally parameters
may be taken from a limited untis timetable integration.

```
Usage: $MYNAME [-c] [-t] [-f] [-b begin] [-e end] [-g group] [-p user] [-m form] [-s subject] [-a abb] [-u username] filename.txt

  -c               set exercise type to confirmation (default)
  -t               set exercise type to writing some text online
  -f               set exercise type uploading result files
  -w               ask webuntis about start of next lesson to fill in end time
  -b begin         start time in the format dd.mm.yyy HH:MM local time (default today 9:00)
  -e end           end time in the format dd.mm.yyy HH:MM local time (default yesterday in a week 20:00)
  -g group         exercise participants as a group identifier
  -p person        exercise participants as a single user identifier
  -m form          when dealing with single person exercises, add their form they are in here explicitly
  -s subject       subject given as a valid tag name (default $ISERV_TAG)
  -a abb           teacher identification code as abbrevation (default $SCHOOL_TOKEN)
  -u pattern       login of the user to read given exercise for
     filename.txt  filename of the basic description file for a new exercise
```


## Context Switches in Teacher's View

Especially in Teacher's View many parameters are needed but some of them will 
be mostly constant over a given period in time. To avoid the repeated typing, 
some parameters may be given as environment variables. 

Those variables may be modified in your shell defaults with some convenience
scripts.

* Switch Topic

Topics are used to prepare prefixes in exercise names and to select tags for
new exercises.

```
$ switch_subject.sh -l en -k
Default School Subject when issuing Exercises:
```

Be aware that the given topic *must* be available in the tag setup your local
administrator prepared for you.

* Setup basic Parameters

It is expected that the backend in use and your teacher shorthand code dont't
change at all during the use of this tool. So use the setup command once to
make the corresponding values your shell defaults.

```
lunette-setup.sh
iServ Backend: sts-lohbruegge.de
School Token: Li
```


## Related Repositories on Github

This is a deliberate collection of repositories relating to [iServ][iserv].

* https://github.com/dunklesToast/IServTool
* https://github.com/dunklesToast/IServ
* https://github.com/felixvossel/IservUploader
* https://github.com/binaro-xyz/IservNachschreibarbeitenBundle
* https://github.com/Lin2D2/IServ-Manager
* https://github.com/corusm/IServ3-Timetable-Mailer

[iserv]: https://www.iserv.eu/
[issues]: https://gitlab.com/backendzeit/lunette/-/issues
[gitlab]: https://gitlab.com/backendzeit/lunette
[github]: https://github.com/mgoellnitz/lunette
