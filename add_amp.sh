#!/bin/sh

echo This has bugs: substitutes stuff between quotes.

for i in `grep ^sub *-conf.in be.pl.in | cut -f2 -d' ' | sort | uniq`; do
 for j in *-conf.in be.pl.in; do
  echo $i:$j
  sed '
  s/\([^_a-z]\)'$i'/\1\&'$i'/g;
  s/\&\+'$i'/\&'$i'/g;
  s/^sub \&\+'$i'/sub '$i'/g;
  s/\$\&/\$/g;s/\@\&/\@/g;s/\%\&/\%/g
  ' $j > $j.1
  mv $j.1 $j
 done
done
