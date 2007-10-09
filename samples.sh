#! /bin/sh

# script file for FontForge for PDF samples creation using fntsample
# Author Євгеній Мещеряков <eugen@debian.org>
# This file is in public domain

set -e

if [ $# != 2 ]
then
	echo "Usage: $0 <new directory> <old directory>"
	exit 1
fi

new_dir="$1"
old_dir="$2"
tmp_dir=`mktemp -dt gensamples.XXXXXXXXXX`

for file in $new_dir/*.ttf
do
	base_name=`basename $file .ttf`
	fntsample -f $file -o $tmp_dir/$base_name.pdf -d $old_dir/$base_name.ttf -l > $tmp_dir/$base_name.txt
	pdfoutline $tmp_dir/$base_name.pdf $tmp_dir/$base_name.txt $base_name.pdf
done

rm -rf $tmp_dir
