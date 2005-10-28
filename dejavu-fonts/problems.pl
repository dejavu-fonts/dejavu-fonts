#!/usr/bin/perl -w

# $Id$

# possible problems finder
# (c)2004,2005 Stepan Roh
# usage: ./problems.pl [-l <0|1|2|3>] sfd_files+

# detected problems (higher levels contain lower levels):
#   level 0:
#     monospaced font (with Mono in name) without indication in Panose (and vice-versa)
#     glyphs in monospaced face with different width
#     not normalized file (looks for DisplaySize or Ref)
#     glyphs without width
#     duplicate glyphs
#   level 1 (default):
#     colorized glyphs with content
#   level 2:
#     different set of mapped content glyphs (first SFD file specified on command line is taken as an etalon)
#   level 3:
#     ligature referencing colorized or missing glyphs
#     ligature in colorized glyph (due to bug in FF <20050502 it causes problems on Mac OS X)
#     ligature in empty glyph

sub process_sfd_file($$);

# glyph name => ( 'dec_enc' => dec_enc, 'hex_enc' => hex_enc )
%glyphs = ();
$glyphs_loaded = 0;
%problems_counter = ();

sub process_sfd_file($$) {
  local ($sfd_file, $max_level) = @_;
  
  sub problem($@) {
    my ($level, $problem, @args) = @_;
    
    if ($level <= $max_level) {
      print $sfd_file, ': [', $level, '] ', $problem, ': ', @args, "\n";
      $problems_counter{'['.$level.'] '.$problem}++;
    }
  }
  
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
      $is_empty = 1;
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
      problem (0, 'old-style "Ref"', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''));
    } elsif (/^Refer:/) {
      $is_empty = 0;
    } elsif (/^DisplaySize:/) {
      problem (0, 'not normalized');
    } elsif (/^EndChar\s*$/) {
      if (!defined $colorized && !$is_empty) {
        $content_glyphs{$curchar}{'dec_enc'} = $dec_enc;
        $content_glyphs{$curchar}{'hex_enc'} = $hex_enc;
        @{$content_glyphs{$curchar}{'ligature'}} = @ligature_refs;
        # only mapped glyphs
        if ($hex_enc) {
          if ($glyphs_loaded) {
            if (!exists $glyphs{$curchar}) {
              problem (2, 'etalon-free glyph', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''));
            }
          } else {
            $glyphs{$curchar}{'dec_enc'} = $dec_enc;
            $glyphs{$curchar}{'hex_enc'} = $hex_enc;
          }
        }
      }
      if (defined $colorized && !$is_empty) {
        problem (1, 'colorized content', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : '') , ': color=', $colorized);
      }
      if (defined $colorized && defined $flags && ($flags =~ /W/)) {
        problem (1, 'colorized content', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : '') , ': color=', $colorized, ', flags=', $flags);
      }
      if (!$is_mono && defined $colorized && ($curwidth != 2048) && ($curwidth != 0)) {
        problem (1, 'colorized content', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : '') , ': color=', $colorized, ', width=', $curwidth);
      }
      if ($curwidth == -1) {
        problem (0, 'glyph w/o width', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''));
      } elsif ($is_mono && defined $flags && ($flags =~ /W/)) {
        if ($font_width == -1) {
          $font_width = $curwidth;
        } elsif ($curwidth != $font_width) {
          problem (0, 'incorrect width', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''), ': font width=', $font_width, ', glyph width=', $curwidth);
        }
      }
      if (defined $colorized && $has_ligature) {
        problem (3, 'colorized ligature', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''), ': color=', $colorized);
      }
      if ($is_empty && $has_ligature) {
        problem (3, 'empty ligature', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''));
      }
      if (exists $all_glyphs{$dec_enc}) {
        problem (0, 'duplicate', $curchar, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''));
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
    problem (0, 'mixed monospace', 'font name=', $fontname, ', panose=', $panose);
  }
  foreach $glyph (sort { $content_glyphs{$a}{'dec_enc'} <=> $content_glyphs{$b}{'dec_enc'} } keys %content_glyphs) {
    my $dec_enc = $content_glyphs{$glyph}{'dec_enc'};
    my $hex_enc = $content_glyphs{$glyph}{'hex_enc'};
    foreach $liga (@{$content_glyphs{$glyph}{'ligature'}}) {
      if (!exists ($content_glyphs{$liga})) {
        problem (3, 'ligature references colorized or missing glyph', $glyph, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''), ': ligature ref=', $liga);
      }
    }
  }
  if ($glyphs_loaded) {
    foreach $glyph (sort { $glyphs{$a}{'dec_enc'} <=> $glyphs{$b}{'dec_enc'} } keys %glyphs) {
      my $dec_enc = $glyphs{$glyph}{'dec_enc'};
      my $hex_enc = $glyphs{$glyph}{'hex_enc'};
      if (!exists $content_glyphs{$glyph}) {
        problem (2, 'missing glyph', $glyph, ' ', $dec_enc, ($hex_enc ? ' U+'.$hex_enc : ''));
      }
    }
  }
  $glyphs_loaded = 1;
}

if (!@ARGV) {
  print STDERR "usage: [-l <0|1|2|3>] sfd_files+\n";
  exit 1;
}

$max_level = 1;
if ($ARGV[0] eq '-l') {
  shift @ARGV;
  $max_level = shift @ARGV;
}
@sfd_files = @ARGV;

foreach $sfd_file (@sfd_files) {
  process_sfd_file ($sfd_file, $max_level);
}

foreach $problem (sort keys %problems_counter) {
  print $problems_counter{$problem}, ' problems of type "', $problem, '"', "\n";
}

1;
