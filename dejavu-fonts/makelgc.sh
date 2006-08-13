#!/bin/sh

# $Id$

mkdir lgc
echo "Creating LGC derivative"
for src in *.sfd; do
  out=lgc/`echo $src | sed s,DejaVu,DejaVuLGC,`
  echo "$src -> $out"
  sed -e 's,FontName: DejaVu,FontName: DejaVuLGC,'\
      -e 's,FullName: DejaVu,FullName: DejaVu LGC,'\
      -e 's,FamilyName: DejaVu,FamilyName: DejaVu LGC,' < $src > $out
done
cd lgc
echo "Stripping unwanted glyphs"
fontforge -script - *.sfd <<END
i = 1
while ( i < \$argc )
  Open(\$argv[i], 1)

  Select(0u0530, 0u1cff)
  SelectMore(0u2c00, 0u2c5f)
  SelectMore(0u2cff, 0ua6ff)
  SelectMore(0ua800, 0udfff)
  SelectMore(0uf900, 0ufaff)
  SelectMore(0ufb07, 0ufe1f)
  SelectMore(0ufe30, 0uffef)
#  SelectMore(0u10000, 0ueffff)
  Clear()
  Save(\$argv[i])
  i++
endloop
END
echo "Generating TTF"
mkdir generated
../generate.pe *.sfd
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
(cd packaged; tar czvf $name.tar.gz $name)
(cd packaged; zip -rv $name.zip $name)
