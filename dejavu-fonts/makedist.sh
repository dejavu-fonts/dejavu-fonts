#!/bin/sh

# $Id$

version=$1
echo Making distribution of DejaVu fonts $version
mkdir packaged/dejavu-sfd-$version
cp *.sfd *.pe README LICENSE AUTHORS NEWS BUGS status.txt packaged/dejavu-sfd-$version
(cd packaged; tar czvf dejavu-sfd-$version.tar.gz dejavu-sfd-$version)
mkdir packaged/dejavu-ttf-$version
cp generated/*.ttf README LICENSE AUTHORS NEWS BUGS status.txt packaged/dejavu-ttf-$version
(cd packaged; tar czvf dejavu-ttf-$version.tar.gz dejavu-ttf-$version)
