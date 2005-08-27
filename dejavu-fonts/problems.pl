#!/usr/bin/perl -w

# $Id$

# possible problems finder
# (c)2004,2005 Stepan Roh
# usage: ./problems.pl [-w] sfd_files+

# detected problems (W = warning visible only with -w):
#   colorized glyphs with content
#   glyphs in monospaced face with different width
#   monospaced font (with Mono in name) without indication in Panose (and vice-versa)
#   ligature in colorized glyph (due to bug in FF <20050502 it causes problems on Mac OS X)
#   ligature in empty glyph
#   W: ligature referencing colorized or missing glyphs
#   different set of mapped content glyphs (first SFD file specified on command line is taken as an etalon)

sub process_sfd_file($$);

# glyph name => ( 'dec_enc' => dec_enc, 'hex_enc' => hex_enc )
%glyphs = ();
$glyphs_loaded = 0;

sub process_sfd_file($$) {
  my ($sfd_file, $with_warns) = @_;
  
  my $curchar = '';
  my $hex_enc = '';
  my $dec_enc = 0;
  my $colorized;
  my $flags;
  my ($fontname, $panose, $is_mono_name, $is_mono_panose) = ('', '', 0, 0);
  my $is_mono = 0;
  my $font_width = -1;
  my $curwidth = 0;
  my $has_ligature = 0;
  my $is_empty = 1;
  my %content_glyphs = ();
  my @ligature_refs = ();
  my %all_glyphs = ();
  open (SFD, $sfd_file) || die "Unable to open $sfd_file : $!\n";
  while (<SFD>) {
    if (/^StartChar:\s*(\S+)\s*$/) {
      $curchar = $1;
      $hex_enc = '';
      $dec_enc = 0;
      $curwidth = -1;
      undef $colorized;
      undef $flags;
      $has_ligature = 0;
      @ligature_refs = ();
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
    } elsif (/^Ligature:\s*\S*\s*\S*\s*\S*\s*(.*?)\s*$/) {
      @ligature_refs = split(/\s+/, $1);
      $has_ligature = 1;
    } elsif (/^Fore\s*$/) {
      $is_empty = 0;
    } elsif (/^Ref:/) {
      $is_empty = 0;
    } elsif (/^EndChar\s*$/) {
      if (!defined $colorized && !$is_empty) {
        $content_glyphs{$curchar}{'dec_enc'} = $dec_enc;
        $content_glyphs{$curchar}{'hex_enc'} = $hex_enc;
        @{$content_glyphs{$curchar}{'ligature'}} = @ligature_refs;
        # only mapped glyphs
        if ($hex_enc) {
          if ($glyphs_loaded) {
            if (!exists $glyphs{$curchar}) {
              print $sfd_file, ': etalon-free glyph: ', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''), "\n";
            }
          } else {
            $glyphs{$curchar}{'dec_enc'} = $dec_enc;
            $glyphs{$curchar}{'hex_enc'} = $hex_enc;
          }
        }
      }
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
      if (exists $all_glyphs{$dec_enc}) {
        print $sfd_file, ': duplicate: ', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''), "\n";
      }
      $all_glyphs{$dec_enc} = 1;
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
  close (SFD);
  if ($is_mono_name != $is_mono_panose) {
    print $sfd_file, ': mixed monospace: font name=', $fontname, ', panose=', $panose, "\n";
  }
  foreach $glyph (sort { $content_glyphs{$a}{'dec_enc'} <=> $content_glyphs{$b}{'dec_enc'} } keys %content_glyphs) {
    my $dec_enc = $content_glyphs{$glyph}{'dec_enc'};
    my $hex_enc = $content_glyphs{$glyph}{'hex_enc'};
    foreach $liga (@{$content_glyphs{$glyph}{'ligature'}}) {
      if ($with_warns && !exists ($content_glyphs{$liga})) {
        print $sfd_file, ': ligature references colorized or missing glyph: ', $glyph, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''), ': ligature ref=', $liga, "\n";
      }
    }
  }
  if ($glyphs_loaded) {
    foreach $glyph (sort { $glyphs{$a}{'dec_enc'} <=> $glyphs{$b}{'dec_enc'} } keys %glyphs) {
      my $dec_enc = $glyphs{$glyph}{'dec_enc'};
      my $hex_enc = $glyphs{$glyph}{'hex_enc'};
      if (!exists $content_glyphs{$glyph}) {
        print $sfd_file, ': missing glyph: ', $glyph, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''), "\n";
      }
    }
  }
  $glyphs_loaded = 1;
}

if (!@ARGV) {
  print STDERR "usage: [-w] sfd_files+\n";
  exit 1;
}

$with_warns = 0;
if ($ARGV[0] eq '-w') {
  $with_warns = 1;
  shift @ARGV;
}
@sfd_files = @ARGV;

foreach $sfd_file (@sfd_files) {
  process_sfd_file ($sfd_file, $with_warns);
}

1;
