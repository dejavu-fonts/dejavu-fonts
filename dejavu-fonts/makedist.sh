#!/bin/sh

# $Id$

version=$1
echo Making distribution of DejaVu fonts $version
install -d packaged/dejavu-sfd-$version/fontconfig
cp *.sfd *.pe *.sh *.pl README LICENSE AUTHORS NEWS BUGS mes*.txt status.txt unicover.txt langcover.txt Makefile packaged/dejavu-sfd-$version
cp fontconfig/*.conf packaged/dejavu-sfd-$version/fontconfig
(cd packaged; tar cjvf dejavu-sfd-$version.tar.bz2 dejavu-sfd-$version)
mkdir packaged/dejavu-ttf-$version
cp generated/*.ttf README LICENSE AUTHORS NEWS BUGS status.txt unicover.txt langcover.txt packaged/dejavu-ttf-$version
(cd packaged; tar cjvf dejavu-ttf-$version.tar.bz2 dejavu-ttf-$version)
(cd packaged; zip -rv dejavu-ttf-$version.zip dejavu-ttf-$version)
