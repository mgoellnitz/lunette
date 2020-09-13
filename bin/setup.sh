#!/bin/bash
echo -n "iServ Host: "
read ISERV_BACKEND
grep -v ISERV_BACKEND= ~/.bashrc > brc 
mv brc ~/.bashrc
echo "export ISERV_BACKEND=$ISERV_BACKEND" >> ~/.bashrc
echo -n "Your Token: "
read SCHOOL_TOKEN
grep -v SCHOOL_TOKEN= ~/.bashrc > brc 
mv brc ~/.bashrc
echo "export SCHOOL_TOKEN=$SCHOOL_TOKEN" >> ~/.bashrc
