#!/bin/sh

# $Id$

set -e 

test -d generated || mkdir generated
./generate.pe *.sfd
for ttf in *.sfd.ttf ; do 
   mv $ttf generated/$(echo $ttf|sed s+"\.sfd\.ttf+.ttf+g")
done
./ttpostproc.pl generated/*.ttf
