#!/bin/bash

# $Id$

ver=$1
for i in *.sfd; do
  sed "s,DejaVu \(0\.[0-9]\+\.[0-9]\+\|[1-9][0-9]*\.[0-9]\+\),DejaVu $ver," $i > $i.tmp
  mv $i.tmp $i
done
