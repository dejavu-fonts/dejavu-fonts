#!/bin/sh

# $Id$

mkdir generated
./generate.pe *.sfd
./ttpostproc.me generated/*.ttf
