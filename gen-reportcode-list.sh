#!/bin/sh

echo Backends - report codes
echo =======================

for i in be.pl *-conf.in
do
  name=`echo $i | cut -d - -f 1`
  let j=`echo $name | wc -c`
  cap=`echo $name | cut -c 1 | tr a-z A-Z`
  name=$cap`echo $name | cut -c 2-64`

  echo
  echo
  echo $name

  while let j=$[j - 1]
  do
    echo -n -
  done

  echo
  echo

  grep be_report_info $i | sed "s/.*be_report_info *[(] *//" | \
    sed "s/, *\"/ /" | sed "s/\" *[)]\;.*//" | \
    ( while read line;
    do
      if test x = x`echo $line | cut -d ' ' -f 1 | sed s/[0-9]//g`
      then
        code=$[200 + `echo $line | cut -d ' ' -f 1`]
        desc=`echo $line | cut -d ' ' -f 2-`
      else
        code="2??"
        desc=$line
      fi
      echo $code $desc
    done ) | sort

  grep be_report_warning $i | sed "s/.*be_report_warning *[(] *//" | \
    sed "s/, *\"/ /" | sed "s/\" *[)]\;.*//" | \
    ( while read line;
    do
      if test x = x`echo $line | cut -d ' ' -f 1 | sed s/[0-9]//g`
      then
        code=$[300 + `echo $line | cut -d ' ' -f 1`]
        desc=`echo $line | cut -d ' ' -f 2-`
      else
        code="3??"
        desc=$line
      fi
      echo $code $desc
    done ) | sort

  grep be_report_error $i | sed "s/.*be_report_error *[(] *//" | \
    sed "s/, *\"/ /" | sed "s/\" *[)]\;.*//" | \
    ( while read line;
    do
      if test x = x`echo $line | cut -d ' ' -f 1 | sed s/[0-9]//g`
      then
        code=$[400 + `echo $line | cut -d ' ' -f 1`]
        desc=`echo $line | cut -d ' ' -f 2-`
      else
        code="4??"
        desc=$line
      fi
      echo $code $desc
    done ) | sort

  grep be_report_fatal $i | sed "s/.*be_report_fatal *[(] *//" | \
    sed "s/, *\"/ /" | sed "s/\" *[)]\;.*//" | \
    ( while read line;
    do
      if test x = x`echo $line | cut -d ' ' -f 1 | sed s/[0-9]//g`
      then
        code=$[500 + `echo $line | cut -d ' ' -f 1`]
        desc=`echo $line | cut -d ' ' -f 2-`
      else
        code="5??"
        desc=$line
      fi
      echo $code $desc
    done ) | sort
done
