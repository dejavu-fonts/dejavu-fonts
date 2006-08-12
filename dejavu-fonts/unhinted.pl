#!/usr/bin/perl -w

# $Id$

# output (TT-)unhinted glyphs
# (c)2005 Stepan Roh (PUBLIC DOMAIN)
# usage: ./unhinted.pl [-v] [-c] sfd_files+

sub parse_sfd_file($$$);

sub parse_sfd_file($$$) {
  my ($sfd_file, $verbose, $composites) = @_;
  
  open (SFD, $sfd_file) || die "Unable to open $sfd_file : $!\n";
  print $sfd_file, ': ';
  my $typeface = '';
  my $curchar = '';
  my $hex_enc = '';
  my $empty = 0;
  my $hinted = 0;
  my $total = 0;
  my $unhinted = 0;
  my $experimental = 0;
  my @unhinted = ();
  my $contours = 0;
  while (<SFD>) {
    if (/^FullName:\s+\S+\s+(.*?)\s*$/) {
      $typeface = $1;
      $experimental = ($typeface =~ /Condensed|(Serif.*Oblique)/);
    } elsif (/^StartChar:\s*(\S+)\s*$/) {
      $curchar = $1;
      $hex_enc = '';
      $empty = 0;
      $hinted = 0;
      $contours = 0;
    } elsif (/^TtfInstrs:/) {
      $hinted = 1;
    } elsif (/^Colour:/) {
      # XXX this is quick'n'dirty hack to detect non-empty glyphs
      $empty = 1;
    } elsif (/^Fore$/) {
      $contours = 1;
    } elsif (/^Encoding:\s*\d+\s*(\d+)\s*\d+\s*$/) {
      $hex_enc = sprintf ('%04X', $1);
    } elsif ($hex_enc && !$empty && /^EndChar\s*$/) {
       $total++;
       if (($composites || $contours) && !$hinted) {
         $unhinted++;
         push (@unhinted, $curchar . ' (U+' . $hex_enc . ')');
       }
    }
  }
  print "[experimental] " if ($experimental);
  printf "%.0d%% (%d/%d)", $unhinted / $total * 100, $unhinted, $total;
  print "\n";
  print '   ', join (', ', @unhinted), "\n" if ($verbose);
  close (SFD);
}

if (@ARGV < 1) {
  print STDERR "usage: [-v] [-c] sfd_files+\n";
  exit 1;
}

while ($ARGV[0] =~ /^-/) {
  if ($ARGV[0] eq '-v') {
    $verbose = 1;
  } elsif ($ARGV[0] eq '-c') {
    $composites = 1;
  } else {
    last;
  }
  shift @ARGV;
}
@sfd_files = @ARGV;

foreach $sfd_file (@sfd_files) {
  parse_sfd_file ($sfd_file, $verbose, $composites);
}

1;
