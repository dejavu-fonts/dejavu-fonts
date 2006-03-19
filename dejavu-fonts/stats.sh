#!/bin/sh

# $Id$

# DejaVu fonts statistics generator
# (c)2005 Stepan Roh (PUBLIC DOMAIN)
# usage: ./stats.sh

# Motto: "To proof that each task can be coded in very complicated way."

echo "Version   New glyphs*)"
echo "--------  ----------"
versions=`grep 'U+' status.txt \
 | tr -s ' ' \
 | cut -d' ' -f 3 \
 | sed 's,original,0.0,' \
 | sed 's,^\(.\)\.\(.\)$,\1.0\2,' \
 | sort \
 | uniq \
 | sed 's,^\(.\).0\(.\)$,\1.\2,' \
 | sed 's,0\.0,original,'`
for ver in $versions; do
  sver=`echo $ver | sed 's,\.,\\\\.,'`
  count=`grep "^U+.*$sver\( \|$\)" status.txt | wc -l`
  printf '%-8s %10i\n' $ver $count
done
echo
echo "*) some glyphs may be counted multiple times if they were added to different faces in different versions"
