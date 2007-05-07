#!/bin/sh

# $Id$

set -e 

test -d generated || mkdir generated
./generate.pe *.sfd
./ttpostproc.pl generated/*.ttf
