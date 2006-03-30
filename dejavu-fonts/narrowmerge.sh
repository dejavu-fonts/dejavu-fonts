#!/bin/sh

# $Id$

# This script will merge new glyphs into the condensed faces.

# It scans for Condensed faces in the current directory and creates
# new files called DejaVuCondensed*.sfd.merged

# The script requires that all fonts are normalized with
# sfdnormalize.pl. The newly created .merged file is automatically
# normalized


for tofile in *Condensed*.sfd; do
	fromfile=`echo $tofile | sed 's,Condensed,,'`
	
	echo "Merging: $fromfile"
	
	# making new narrow font
	./narrow.pe 90 $fromfile
	
	# normalizing the new narrow font
	./sfdnormalize.pl $fromfile.narrow
	
	# merging the new normalized narrow font into the existing Condensed font
	mergelist=`./merge.pl $fromfile.narrow.norm $tofile $tofile.merged`
	
	# normalizing the new merged font
	./sfdnormalize.pl $tofile.merged
	
	# removing files that aren't needed anymore
	if [ -e $fromfile.narrow ]; then
		rm $fromfile.narrow
	fi
	if [ -e $fromfile.narrow.norm ]; then
		rm $fromfile.narrow.norm
	fi
	if [ -e $tofile.merged ]; then
		rm $tofile.merged
	fi

	# renaming normalized file
	if [ -e $tofile.merged.norm ]; then
		mv $tofile.merged.norm $tofile.merged
	fi
	
done
