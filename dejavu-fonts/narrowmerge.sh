#!/bin/sh

# $Id$

for tofile in *Condensed*.sfd; do
  fromfile=`echo $tofile | sed 's,Condensed,,'`
  ./narrowmerge.pe 90 $tofile.merged `./merge.pl $fromfile $tofile $tofile.merged`
  if [ -e $tofile.merged ]; then
    rm $tofile.merged
  fi
done
