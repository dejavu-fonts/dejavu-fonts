#!/bin/sh

# $Id$

set -e 

test -d generated || mkdir generated
for srcfile in *.sfd
do 
    ./generate.pe $srcfile
done
./ttpostproc.pl generated/*.ttf
