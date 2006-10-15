#!/bin/sh

# $Id$

test -d generated || mkdir generated
./generate.pe *.sfd
./ttpostproc.pl generated/*.ttf
