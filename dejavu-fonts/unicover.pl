#!/usr/bin/perl -w

# $Id$

# unicode coverage analyzator
# (c)2004 Stepan Roh
# usage: ./unicover.pl unicode_data_file blocks_file sfd_file
#  unicode data file can be downloaded from http://www.unicode.org/Public/UNIDATA/UnicodeData.txt
#  blocks file can be downloaded from http://www.unicode.org/Public/UNIDATA/Blocks.txt

sub parse_blocks_file($);
sub parse_unicode_data_file($);
sub parse_sfd_file($);
sub inc_coverage($);
sub print_coverage();
sub disable_char($);

$debug = 0;

if ($debug) {
  use Data::Dumper;

  $Data::Dumper::Indent = 1;
  $Data::Dumper::Sortkeys = 1;
  $Data::Dumper::Purity = 1;
}

# map (start dec => ( 'name' => block name, 'end' => end dec, 'coverage' => coverage, 'disabled' => ( disabled chars map* ) )
%blocks = ();

sub parse_blocks_file($) {
  my ($blocks_file) = @_;

  open (F, $blocks_file) || die "Unable to open $blocks_file : $!\n";
  while (<F>) {
    next if (/^\s*(#|$)/);
    my ($start, $end, $name) = ($_ =~ /^(.*?)\.\.(.*?);\s*(.*?)\s*$/);
    $start = hex ($start);
    $end = hex ($end);
    $blocks{$start}{'name'} = $name;
    $blocks{$start}{'end'} = $end;
  }
  close (F);
}

sub disable_char($) {
  my ($dec_enc) = @_;

  foreach $block_start (keys %blocks) {
    my ($block_end) = $blocks{$block_start}{'end'};
    if (($dec_enc >= $block_start) && ($dec_enc <= $block_end)) {
      $blocks{$block_start}{'disabled'}{$dec_enc} = 1;
      last;
    }
  }
}

sub parse_unicode_data_file($) {
  my ($ud_file) = @_;

  open (F, $ud_file) || die "Unable to open $ud_file : $!\n";
  while (<F>) {
    next if (/^\s*(#|$)/);
    my ($enc, $name) = split (/;/);
    $enc = hex ($enc);
    disable_char ($enc) if ($name =~ /^</);
  }
  close (F);
}

sub inc_coverage($) {
  my ($dec_enc) = @_;
  
  foreach $block_start (keys %blocks) {
    my ($block_end) = $blocks{$block_start}{'end'};
    if (($dec_enc >= $block_start) && ($dec_enc <= $block_end)) {
      if (!exists $blocks{$block_start}{'disabled'}{$dec_enc}) {
        $blocks{$block_start}{'coverage'}++;
      }
      last;
    }
  }
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
      inc_coverage ($curenc);
    }
  }
  close (F);
}

sub print_coverage() {
  print <<END;
This is the Unicode coverage file for DejaVu fonts
(\$Id\$)

Control and similar characters are discounted from totals.

END
  foreach $block_start (sort { $a <=> $b } keys %blocks) {
    my ($block_end) = $blocks{$block_start}{'end'};
    my ($name) = $blocks{$block_start}{'name'};
    my ($coverage) = $blocks{$block_start}{'coverage'};
    $coverage = 0 if (!defined $coverage);
    my ($disabled) = scalar keys %{$blocks{$block_start}{'disabled'}};
    $disabled = 0 if (!defined $disabled);
    my ($length) = $block_end - $block_start + 1 - $disabled;
    my ($percent) = $coverage/$length * 100;
    printf "U+%04x %-40s ", $block_start, $name;
    if ($percent > 0) {
      printf "%3d%%", $percent;
    } else {
      print "    ";
    }
    print " ($coverage/$length)\n";
  }
}

if (@ARGV < 3) {
  print STDERR "usage: unicode_data_file blocks_file sfd_file\n";
  exit 1;
}

$unicode_data_file = shift @ARGV;
$blocks_file = shift @ARGV;
$sfd_file = shift @ARGV;

parse_blocks_file($blocks_file);
parse_unicode_data_file($unicode_data_file);
parse_sfd_file($sfd_file);
print_coverage();

if ($debug) {
  print STDERR Data::Dumper->Dump([\%blocks], ['*blocks']);
}

1;
