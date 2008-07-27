#!/bin/sh

# call this script from the main directory like scripts/wikidownloadtemplate.sh

# use the output of this script to update http://dejavu.sourceforge.net/wiki/index.php?title=Download


# assumes that version in Makefile is correct (which it should be or something was done wrong)
VERSION=`grep "VERSION = " Makefile -m1 | cut -d' ' -f3`

# directory where to look for the files
DIRECTORY=`grep "DISTDIR = " Makefile -m1 | cut -d' ' -f3`


function makeentry
# usage: makeentry filename description
{
	file=$DIRECTORY/$1

	if [ -f $file ]; then

		echo "{{SFFile|"

        	echo "  name= $1"
		echo "| size= `wc -c $file | cut -f1 -d' '`"
		echo "| desc= $2"
		echo "| md5= `md5sum $file | cut -f1 -d' '`"
		echo "| sha256= `sha256sum $file | cut -f1 -d' '`"

		echo "}}"

	else

		echo "Error: File '$file' does not exist"

	fi
}


makeentry "dejavu-fonts-ttf-${VERSION}.tar.bz2" "TrueType fonts packed as [[Wikipedia:tar.bz2|tar.bz2]] archive"

makeentry "dejavu-fonts-ttf-${VERSION}.zip" "TrueType fonts packed as [[Wikipedia:ZIP (file format)|zip]] archive"

makeentry "dejavu-fonts-${VERSION}.tar.bz2" "Fonts in source form (SFD) for [[FontForge]]"

makeentry "dejavu-lgc-fonts-ttf-${VERSION}.tar.bz2" "DejaVu LGC (Latin, Greek, Cyrillic) TrueType fonts packed as [[Wikipedia:tar.bz2|tar.bz2]] archive"

makeentry "dejavu-lgc-fonts-ttf-${VERSION}.zip" "DejaVu LGC (Latin, Greek, Cyrillic) TrueType fonts packed as [[Wikipedia:ZIP (file format)|zip]] archive"

makeentry "dejavu-sans-ttf-${VERSION}.zip" "This package only includes DejaVuSans.ttf in a [[Wikipedia:ZIP (file format)|zip]] archive"

