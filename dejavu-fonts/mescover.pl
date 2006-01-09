#!/usr/bin/perl -w

# $Id$

# MES coverage analyzer
# (c)2005 Stepan Roh
# usage: ./mescover.pl mes_spec_file sfd_files+

sub parse_mes_spec_file($);
sub init_mes_glyphs();
sub print_mes_glyphs();
sub parse_sfd_file($);

# map (MES glyph dec => 1)
%mes_glyphs = ();
$mes_collection = 'UNKNOWN';

sub parse_mes_spec_file($) {
  my ($mes_file) = @_;
  
  open (F, $mes_file) || die "Unable to open $mes_file : $!\n";
  my $plane = '00';
  while (<F>) {
    if (/^Collection Name:\s+(.*?)\s*$/) {
      $mes_collection = $1;
    } elsif (/^Plane\s+(\d+)\s*$/) {
      $plane = $1;
    } elsif (/^([A-F0-9]+)\s+(.*?)\s*$/) {
      my $row = $1;
      my @cells = split(/\s+/, $2);
      foreach $cell (@cells) {
        my @range = split(/-/, $cell);
        if (@range == 1) {
          my $hexenc = $plane.$row.$range[0];
          my $decenc = hex($hexenc);
          $mes_glyphs{$decenc} = 1;
        } else {
          my $hexenc_start = $plane.$row.$range[0];
          my $decenc_start = hex($hexenc_start);
          my $hexenc_end = $plane.$row.$range[1];
          my $decenc_end = hex($hexenc_end);
          for (my $decenc = $decenc_start; $decenc <= $decenc_end; $decenc++) {
            $mes_glyphs{$decenc} = 1;
          }
        }
      }
    }
  }
  close (F);
}

sub init_mes_glyphs() {
  foreach $decenc (keys %mes_glyphs) {
    $mes_glyphs{$decenc} = 1;
  }
}

sub print_mes_glyphs() {
  my $cnt = 0;
  my $missed = 0;
  my $lastenc = -100;
  my $in_range = 0;
  foreach $decenc (sort keys %mes_glyphs) {
    if ($mes_glyphs{$decenc} != 0) {
      if ($decenc == $lastenc + 1) {
        $lastenc = $decenc;
        $in_range = 1;
      } else {
        if ($in_range) {
          printf("-U+%04x", $lastenc);
        }
        printf(" U+%04x", $decenc);
        $in_range = 0;
      }
      $lastenc = $decenc;
      $missed++;
    }
    $cnt++;
  }
  if ($in_range) {
    printf("-U+%04x", $lastenc);
  }
  print " [$missed/$cnt]";
}

sub parse_sfd_file($) {
  my ($sfd_file) = @_;
  
  open (F, $sfd_file) || die "Unable to open $sfd_file : $!\n";
  my $curchar = '';
  my $curenc = '';
  my $empty = 0;
  while (<F>) {
    if (/^StartChar:\s*(\S+)\s*$/) {
      $curchar = $1;
      $curenc = '';
      $empty = 0;
    } elsif (/^Colour:/) {
      # XXX this is quick'n'dirty hack to detect non-empty glyphs
      $empty = 1;
    } elsif (/^Encoding:\s*\d+\s*(\d+)\s*\d+\s*$/) {
      $curenc = $1;
    } elsif ($curenc && !$empty && /^EndChar\s*/) {
      if (defined $mes_glyphs{$curenc}) {
        $mes_glyphs{$curenc} = 0;
      }
    }
  }
  close (F);
}

if (@ARGV < 2) {
  print STDERR "usage: mes_spec_file sfd_files+\n";
  exit 1;
}

$mes_spec_file = shift @ARGV;
parse_mes_spec_file($mes_spec_file);
print "Missing glyphs from collection $mes_collection\n\n";
while (@ARGV) {
  $sfd_file = shift @ARGV;
  print $sfd_file, ':';
  init_mes_glyphs();
  parse_sfd_file($sfd_file);
  print_mes_glyphs();
  print "\n";
}

1;
