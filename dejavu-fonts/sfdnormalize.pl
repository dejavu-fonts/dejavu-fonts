#!/usr/bin/perl -w

# $Id$

# SFD normalizer (discards GUI information from SFD files)
# (c)2004 Stepan Roh
# usage: ./sfdnormalize.pl sfd_file(s)
#  will create files with suffix .norm

# changes done:
#   WinInfo - changed to WinInfo: 0 39 16
#   Flags   - discarded O (open)
#   Ref     - changed S (selected) to N (not selected)

foreach $in (@ARGV) {
  my $out = $in . '.norm';
  open (IN, $in) || die "Unable to open $in : $!\n";
  open (OUT, '>'.$out) || die "Unable to open $out : $!\n";
  while (<IN>) {
    s,^WinInfo:.*$,WinInfo: 0 39 16,;
    s,^(Flags:.*?)O(.*)$,$1$2,;
    s,^(Ref:.*?)S(.*)$,$1N$2,;
    print OUT;
  }
  close (IN) || die "Unable to close $in : $!\n";
  close (OUT) || die "Unable to close $out : $!\n";
}

1;
