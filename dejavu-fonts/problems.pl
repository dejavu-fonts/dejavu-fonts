#!/usr/bin/perl -w

# $Id$

# possible problems finder
# (c)2004,2005 Stepan Roh
# usage: ./problems.pl sfd_files+

# detected problems:
#   colorized glyphs with content
#   glyphs in monospaced face with different width
#   monospaced font (with Mono in name) without indication in Panose (and vice-versa)
#   ligature in colorized glyph (due to bug in FF it causes problems on Mac OS X)
#   ligature in empty glyph (same as above)

sub process_sfd_file($);

sub process_sfd_file($) {
  my ($sfd_file) = @_;
  
  open (SFD, $sfd_file) || die "Unable to open $sfd_file : $!\n";
  my $curchar = '';
  my $hex_enc = '';
  my $dec_enc = 0;
  my $colorized;
  my $flags;
  my ($fontname, $panose, $is_mono_name, $is_mono_panose);
  my $is_mono = 0;
  my $font_width = -1;
  my $curwidth = 0;
  my $has_ligature = 0;
  my $is_empty = 1;
  while (<SFD>) {
    if (/^StartChar:\s*(\S+)\s*$/) {
      $curchar = $1;
      $hex_enc = '';
      $dec_enc = 0;
      $curwidth = -1;
      undef $colorized;
      undef $flags;
      $has_ligature = 0;
    } elsif (/^Colour:\s*(\S+)\s*/) {
      $colorized = $1;
    } elsif (/^Flags:\s*(\S+)\s*/) {
      $flags = $1;
    } elsif (/^Encoding:\s*(\d+)\s*((?:-|\d)+)\s*\d+\s*$/) {
      $dec_enc = $1;
      if ($2 > -1) {
        $hex_enc = sprintf ('%04x', $2);
      }
    } elsif (/^Width:\s*(\S+)\s*/) {
      $curwidth = $1;
    } elsif (/^Ligature:/) {
      $has_ligature = 1;
    } elsif (/^Fore\s*$/) {
      $is_empty = 0;
    } elsif (/^Ref:/) {
      $is_empty = 0;
    } elsif (/^EndChar\s*$/) {
      if (defined $colorized && defined $flags && ($flags =~ /W/)) {
        print $sfd_file, ': colorized content: ', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : '') , ': color=', $colorized, ', flags=', $flags, "\n";
      }
      if (defined $colorized && ($curwidth != 2048)) {
        print $sfd_file, ': colorized content: ', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : '') , ': color=', $colorized, ', width=', $curwidth, "\n";
      }
      if ($curwidth == -1) {
        print $sfd_file, ': glyph w/o width: ', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''), "\n";
      } elsif ($is_mono && defined $flags && ($flags =~ /W/)) {
        if ($font_width == -1) {
          $font_width = $curwidth;
        } elsif ($curwidth != $font_width) {
          print $sfd_file, ': incorrect width: ', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''), ': font width=', $font_width, ', glyph width=', $curwidth, "\n";
        }
      }
      if (defined $colorized && $has_ligature) {
        print $sfd_file, ': colorized ligature: ', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''), ': color=', $colorized, "\n";
      }
      if ($is_empty && $has_ligature) {
        print $sfd_file, ': empty ligature: ', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''), "\n";
      }
    } elsif (/^FontName:\s*(.*?)\s*$/) {
      $fontname = $1;
      $is_mono_name = ($fontname =~ /mono/i);
      $is_mono = 1 if ($is_mono_name);
    } elsif (/^Panose:\s*(.*?)\s*$/) {
      $panose = $1;
      $is_mono_panose = ((split(/\s+/, $panose))[3] == 9);
      $is_mono = 1 if ($is_mono_panose);
    }
  }
  if ($is_mono_name != $is_mono_panose) {
    print $sfd_file, ': mixed monospace: font name=', $fontname, ', panose=', $panose, "\n";
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
