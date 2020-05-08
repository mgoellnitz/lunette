# iServ related Command Line Tools

[![License](https://img.shields.io/github/license/mgoellnitz/lunette.svg)](https://github.com/mgoellnitz/lunette/blob/master/LICENSE)
[![Build](https://img.shields.io/gitlab/pipeline/backendzeit/lunette.svg)](https://gitlab.com/backendzeit/lunette/pipelines)

"Hacking iServ for Fun and ... whatever."

After getting past the cookie and login stuff I started to address the following
objectives with a generic collection of command line scripts.

* collecting tasks and materials for offline use in student's view
* collection submission for tasks for offline use in teacher's view

Sorry to tell you that due to personal preferences in our household all these
scripts are and will be only linux-tested.

## Feedback

This repository is available at [github][github] and [gitlab][gitlab]. Please 
prefer the [issues][issues] section of this repository at [gitlab][gitlab]
for feedback.

## Naming

While for any generic usage with [iServ][iserv] the origin of the name might be
mysterious, it translates very well:

lunette: telescope, Fr.

The real origin of the name is the acronym of an acronym for a given instance
of [iServ][iserv] with just `te` appended to sound be bit french.

## Usage

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
of the environent variable `ISERV_BACKEN` are taken into account.

```
export ISERV_BACKEND=https://hansa-schule.net/iserv
```

Session creation results in two files in the home directory of the current
user: `~/.session.user.name` holding the backend to be used for the user and 
`~/.iserv.user.name` holding the cookies for the current session of that user.

* List Exercises

To list the current exercises, issue the command

```
./exercises.sh [user.name]
```

Without any parameters this command would list the exercises of one random user
with a currently valid session. So, if you only have one open session, this is
sufficient. If you are working with multiple sessions in parallel, at least
portions of the username need to be given as a parameter.

```
$ ./exercises.sh claire
Exercises for claire.delune@https://bornbrook.de/iserv
```

It is also possible to list past exercises with an optional `-p` parameter.

```
$ ./exercises.sh -p claire
Exercises for claire.delune@https://bornbrook.de/iserv
```

* Show one Exercise

To show the details of one single exercise, issue the command

```
./exercise.sh exerciseid
```

with an exerciseid drawn from the exercise listing command. As with other 
commands an optional pattern can be given to select the active iServ session
to use.

```
./exercise.sh -u claire exerciseid
```

To download the attachments to a local folder `exerciseid/`, add the download
option.

```
./exercise.sh -d exerciseid
```

This will result in a subfolder of the current folder named `exerciseid` 
containing the files mentioned in the exercise details.

## Quickly fetch all Exercises as a local Mirror

```
for e in $(bin/exercises.sh -p|cut -d ' ' -f 1) ; do bin/exercise.sh -d $e > $e.txt ; done
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
