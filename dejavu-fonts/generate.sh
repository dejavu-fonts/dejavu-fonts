#!/bin/sh

mkdir generated
./generate.pe *.sfd
./ttpostproc.me generated/*.ttf
