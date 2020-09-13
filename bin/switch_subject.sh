#!/bin/bash
echo -n "Subject: "
read SCHOOL_SUBJECT
grep -v SCHOOL_SUBJECT= ~/.bashrc > brc 
mv brc ~/.bashrc
echo "export SCHOOL_SUBJECT=$SCHOOL_SUBJECT" >> ~/.bashrc
