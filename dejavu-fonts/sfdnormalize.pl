#!/usr/bin/perl -w

# $Id$

# SFD normalizer (discards GUI information from SFD files)
# (c)2004 Stepan Roh
# usage: ./sfdnormalize.pl sfd_file(s)
#  will create files with suffix .norm

# changes done:
#   WinInfo - discarded
#   Flags   - discarded O (open)
#   Ref     - changed S (selected) to N (not selected)
#   Fore, Back, SplineSet, Grid
#           - all points have 4 masked out from flags (selected)

# !!! Always review changes done by this utility !!!

foreach $in (@ARGV) {
  my $out = $in . '.norm';
  open (IN, $in) || die "Unable to open $in : $!\n";
  open (OUT, '>'.$out) || die "Unable to open $out : $!\n";
  my $in_spline_set = 0;
  while (<IN>) {
    next if (/^WinInfo:/);
    s,^(Flags:.*?)O(.*)$,$1$2,;
    s,^(Ref:.*?)S(.*)$,$1N$2,;
    if (/^(Fore|Back|SplineSet|Grid)\s*$/) {
      $in_spline_set = 1;
    } elsif (/^EndSplineSet\s*$/) {
      $in_spline_set = 0;
    } elsif ($in_spline_set) {
      s/(\s+)(\S+?)(,\S+\s*)$/$1.($2 & ~4).$3/e;
    }
    print OUT;
  }
  close (IN) || die "Unable to close $in : $!\n";
  close (OUT) || die "Unable to close $out : $!\n";
}

1;
