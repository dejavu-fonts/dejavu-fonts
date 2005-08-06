#!/usr/bin/perl -w

# $Id$

# SFD normalizer (discards GUI information from SFD files)
# (c)2004,2005 Stepan Roh
# usage: ./sfdnormalize.pl sfd_file(s)
#  will create files with suffix .norm

# changes done:
#   WinInfo - discarded
#   DisplaySize
#           - discarded
#   Flags   - discarded O (open)
#   Ref     - changed S (selected) to N (not selected)
#   Fore, Back, SplineSet, Grid
#           - all points have 4 masked out from flags (selected)
#   recalculate number of characters and positional encoding
#   change Refer to backwards-compatible Ref

# !!! Always review changes done by this utility !!!

sub process_sfd_file($);

sub process_sfd_file($) {
  my ($sfd_file) = @_;

  my $out = $sfd_file . '.norm';
  
  open (SFD, $sfd_file) || die "Unable to open $sfd_file : $!\n";
  open (OUT, '>'.$out) || die "Unable to open $out : $!\n";

  my $curchar = '';
  my %glyphs = ();
  my $in_spline_set = 0;
  my $max_dec_enc = 0;

  while (<SFD>) {
    next if (/^(WinInfo|DisplaySize):/);
    s,^Refer:,Ref:,;
    s,^(Flags:.*?)O(.*)$,$1$2,;
    s,^(Ref:.*?)S(.*)$,$1N$2,;
    if (/^(Fore|Back|SplineSet|Grid)\s*$/) {
      $in_spline_set = 1;
    } elsif (/^EndSplineSet\s*$/) {
      $in_spline_set = 0;
    } elsif ($in_spline_set) {
      s/(\s+)(\S+?)(,\S+\s*)$/$1.($2 & ~4).$3/e;
    }
    if (/^BeginChars:/) {
      $in_chars = 1;
    } elsif (/^EndChars\s*$/) {
      $in_chars = 0;
      # adding of 1 to max_dec_enc is strange, but works
      print OUT "BeginChars: ", $max_dec_enc + 1, " ", scalar (keys %glyphs), "\n";
      foreach $glyph (sort { $glyphs{$a}{'dec_enc'} <=> $glyphs{$b}{'dec_enc'} } keys %glyphs) {
        print OUT "StartChar: ", $glyphs{$glyph}{'name'}, "\n";
        my $dec_enc = $glyphs{$glyph}{'dec_enc'};
        my $mapped_enc = $glyphs{$glyph}{'mapped_enc'};
        print OUT "Encoding: ", $dec_enc, " ", $mapped_enc, " ", $dec_enc, "\n";
        print OUT @{$glyphs{$glyph}{'lines'}};
        print OUT "EndChar\n";
        $pos++;
      }
      print OUT "EndChars\n";
    } elsif (/^StartChar:\s*(\S+)\s*$/) {
      my $name = $1;
      $curchar = $name;
      while (exists $glyphs{$curchar}) {
        $curchar .= '#';
      }
      $glyphs{$curchar}{'name'} = $name;
    } elsif (/^Encoding:\s*(\d+)\s*((?:-|\d)+)\s*(\d+)\s*$/) {
      $dec_enc = $1;
      $max_dec_enc = $dec_enc if ($dec_enc > $max_dec_enc);
      $mapped_enc = $2;
      $pos = $3;
      $glyphs{$curchar}{'dec_enc'} = $dec_enc;
      $glyphs{$curchar}{'mapped_enc'} = $mapped_enc;
      $glyphs{$curchar}{'pos'} = $pos;
    } elsif (/^EndChar\s*$/) {
      $curchar = '';
    } else {
      if (!$in_chars) {
        print OUT;
      } elsif ($curchar eq '') {
        warn "Malformed input file $sfd_file?";
      } else {
        push (@{$glyphs{$curchar}{'lines'}}, $_);
      }
    }
  }

  close (SFD);
  close (OUT);
}

if (!@ARGV) {
  print STDERR "usage: sfd_files+\n";
  exit 1;
}

@sfd_files = @ARGV;

foreach $sfd_file (@sfd_files) {
  process_sfd_file ($sfd_file);
}

1;
