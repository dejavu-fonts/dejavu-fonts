#!/usr/bin/perl -w

# $Id$

# SFD files merger
# (c)2005 Stepan Roh
# usage: ./merge.pl sfd_from sfd_to sfd_out
#  will merge sfd_to with sfd_from into the sfd_out (if there are some merges)
#  will print merged glyph codes on stdout

# SFD = ( 'header' => @header_lines, 'footer' => @footer_lines, 'glyphs' => ( glyphenc => @glyph_lines ) )

sub load_sfd ($) {
  my ($sfdfile) = @_;
  
  my %sfd = ();
  open (SFD, $sfdfile) || die "Unable to open $sfdfile : $!\n";
  # -1 = header, 0 = glyphs, 1 = footer
  my $section = -1;
  my $enc = 0;
  my @cur = ();
  while (<SFD>) {
    if (/^StartChar:/) {
      $section = 0;
    } elsif (/^Encoding:\s*(\d+)/) {
      $enc = $1;
    }
    if ($section == -1) {
      push (@{$sfd{'header'}}, $_);
    } elsif ($section == 1) {
      push (@{$sfd{'footer'}}, $_);
    } else {
      push (@cur, $_);
    }
    if (/^EndChar\s*$/) {
      $section = 1;
      @{$sfd{'glyphs'}{$enc}} = @cur;
      @cur = ();
    }
  }
  close (SFD);
  
  return %sfd;
}

sub save_sfd ($\%) {
  my ($sfdfile, $sfd_ref) = @_;
  
  open (SFD, '>'.$sfdfile) || die "Unable to open $sfdfile : $!\n";
  print SFD @{$$sfd_ref{'header'}};
  foreach $enc (sort { $a <=> $b } keys %{$$sfd_ref{'glyphs'}}) {
    print SFD @{$$sfd_ref{'glyphs'}{$enc}};
  }
  print SFD @{$$sfd_ref{'footer'}};
  close (SFD);
}

sub is_dummy_glyph (\@) {
  my ($glyph_ref) = @_;

  foreach $l (@$glyph_ref) {
    if ($l =~ /^Colour:/) {
      # XXX this is quick'n'dirty hack to detect dummy glyphs
      return 1;
    }
  }
  
  return 0;
}

sub merge_glyphs (\%\%) {
  my ($sfd_from, $sfd_to) = @_;

  my $merged = 0;
  foreach $enc (sort { $a <=> $b } keys %{$$sfd_from{'glyphs'}}) {
    if (!exists ($$sfd_to{'glyphs'}{$enc}) ||
        (!is_dummy_glyph(@{$$sfd_from{'glyphs'}{$enc}}) && is_dummy_glyph(@{$$sfd_to{'glyphs'}{$enc}}))) {
      $$sfd_to{'glyphs'}{$enc} = $$sfd_from{'glyphs'}{$enc};
      print $enc, "\n";
      $merged++;
    }
  }
  
  return $merged;
}

if (@ARGV < 3) {
  print STDERR "usage: $0 sfd_from sfd_to sfd_out\n";
  exit (1);
}

($sfdfile_from, $sfdfile_to, $sfdfile_out) = @ARGV;

%sfd_from = load_sfd ($sfdfile_from);
%sfd_to = load_sfd ($sfdfile_to);
if (merge_glyphs (%sfd_from, %sfd_to) > -1) {
  save_sfd ($sfdfile_out, %sfd_to);
}

1;
