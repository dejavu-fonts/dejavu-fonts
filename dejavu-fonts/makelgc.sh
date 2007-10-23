#!/bin/sh

# $Id$

# check for files needed to generate langcover.txt and unicover.txt for LGC
# Unicode Data
if [ ! -e "UnicodeData.txt" -o ! -e "Blocks.txt" ]; then
 echo "can't read UnicodeData.txt or Blocks.txt\n";
 exit 1; 
fi
# fontconfig fc-lang
if [ ! -d "fc-lang" ]; then
 echo "can't read fc-lang\n";
 exit 1; 
fi

mkdir lgc
echo "Creating LGC derivative"
for src in *.sfd; do
  out=lgc/`echo $src | sed s,DejaVu,DejaVuLGC,`
  echo "$src -> $out"
  sed -e 's,FontName: DejaVu,FontName: DejaVuLGC,'\
      -e 's,FullName: DejaVu,FullName: DejaVu LGC,'\
      -e 's,FamilyName: DejaVu,FamilyName: DejaVu LGC,'\
      -e 's,"DejaVu \(\(Sans\|Serif\)*\( Condensed\| Mono\)*\( Bold\)*\( Oblique\|Italic\)*\)","DejaVu LGC \1",g' < $src > $out
done
cd lgc
echo "Stripping unwanted glyphs"
fontforge -script ../lgc.pe *.sfd
echo "Generating TTF"
mkdir generated
../generate.pe *.sfd
for ttf in *.sfd.ttf ; do 
   mv $ttf generated/$(echo $ttf|sed s+"\.sfd\.ttf+.ttf+g")
done
../ttpostproc.pl generated/*.ttf
../unicover.pl ../UnicodeData.txt ../Blocks.txt DejaVuLGCSans.sfd Sans DejaVuLGCSerif.sfd Serif DejaVuLGCMonoSans.sfd 'Sans Mono' > unicover.txt
../langcover.pl ../fc-lang DejaVuLGCSans.sfd Sans DejaVuLGCSerif.sfd Serif DejaVuLGCMonoSans.sfd 'Sans Mono' > langcover.txt
cd ..

version=$1
if [ -z "$version" ]; then
  echo "No version supplied - no distribution created"
  exit 0
fi
echo "Making LGC distribution of DejaVu fonts $version"
name=dejavu-lgc-ttf-$version
mkdir packaged/$name
cp lgc/generated/*.ttf README LICENSE AUTHORS NEWS BUGS lgc/unicover.txt lgc/langcover.txt packaged/$name
(cd packaged; tar cjvf $name.tar.bz2 $name)
(cd packaged; zip -rv $name.zip $name)
