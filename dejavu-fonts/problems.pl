#!/usr/bin/perl -w

# $Id$

# possible problems finder
# (c)2004 Stepan Roh
# usage: ./problems.pl sfd_files+

sub process_sfd_file($);

sub process_sfd_file($) {
  my ($sfd_file) = @_;
  
  open (SFD, $sfd_file) || die "Unable to open $sfd_file : $!\n";
  my $curchar = '';
  my $hex_enc = '';
  my $dec_enc = 0;
  my $colorized;
  my $flags;
  while (<SFD>) {
    if (/^StartChar:\s*(\S+)\s*$/) {
      $curchar = $1;
      $hex_enc = '';
      $dec_enc = 0;
      undef $colorized;
      undef $flags;
    } elsif (/^Colour:\s*(\S+)\s*/) {
      $colorized = $1;
    } elsif (/^Flags:\s*(\S+)\s*/) {
      $flags = $1;
    } elsif (/^Encoding:\s*(\d+)\s*((?:-|\d)+)\s*\d+\s*$/) {
      $dec_enc = $1;
      if ($2 > -1) {
        $hex_enc = sprintf ('%04x', $2);
      }
    } elsif (/^EndChar\s*$/) {
      if (defined $colorized && defined $flags) {
        print $sfd_file, ': ', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : '') , ': color=', $colorized, ', flags=', $flags, "\n";
      }
    }
  }
  close (SFD);
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
