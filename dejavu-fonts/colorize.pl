#!/usr/bin/perl -w

# $Id$

# glyph comment colorizing
# (c)2004 Stepan Roh
# usage: ./colorize.pl color sfd_files+ < glyph_codes_file
#  will create files with suffix .color
#  color is either yellow, green or hexadecimal 24bit value (0xff0000 is red)
#  glyph_codes_file should contain codes of glyphs to be colored delimited by whitespace and/or commas
#  - glyph codes are U+nnnn (nnnn is hexadecimal)
#  - syntax for code ranges: U+nnnn-U+nnnn (no whitespace inside)
#  file colorize.pe is created during the execution (it is safe to remove it after)

# change to the fontforge binary location if it is not in the system PATH
$fontforge = "fontforge";

sub decode_color($) {
  my ($color) = @_;
  if ($color eq 'yellow' || $color eq 'wip') {
    return "0xffff00";
  } elsif ($color eq 'green' || $color eq 'req') {
    return "0x00ff00";
  }
  return $color;
}

sub decode_glyph_code($) {
  my ($code) = @_;
  $code =~ s/^[Uu]\+//;
  return $code;
}

sub parse_glyph_codes_from_stdin() {
  my @ret = ();
  my @input = split (/(?:\s|,)+/, join ('', <STDIN>));
  foreach $token (@input) {
    if ($token =~ /^(.*)-(.*)$/) {
      push (@ret, decode_glyph_code ($1), decode_glyph_code ($2));
    } else {
      push (@ret, decode_glyph_code ($token));
      push (@ret, decode_glyph_code ($token));
    }
  }
  return @ret;
}

if (@ARGV < 2) {
  print STDERR "usage: $0 color sfd_files+ < glyph_codes_file\n";
  exit (1);
}

@glyph_codes = parse_glyph_codes_from_stdin();
$color = decode_color(shift @ARGV);

open (PE, '>colorize.pe') || die "Unable to open colorize.pe : $!\n";
print PE 'i = 1
while ( i < $argc )
  Open($argv[i], 1)
  Select('.join (',', map { '0u'.$_ } @glyph_codes).')
  SetCharColor('.$color.')
  Save($argv[i] + ".color")
  i++
endloop
';
close (PE) || die "Unable to close colorize.pe : $!\n";

system ($fontforge, '-script', 'colorize.pe', @ARGV);

1;
