#!/usr/bin/perl -w

# $Id$

# unicode coverage analyzator
# (c)2004,2005 Stepan Roh (PUBLIC DOMAIN)
# usage: ./unicover.pl unicode_data_file blocks_file sfd_file1 label1 (sfd_file2 label2...)
#  unicode data file can be downloaded from http://www.unicode.org/Public/UNIDATA/UnicodeData.txt
#  blocks file can be downloaded from http://www.unicode.org/Public/UNIDATA/Blocks.txt

sub parse_blocks_file($);
sub parse_unicode_data_file($);
sub parse_sfd_file($);
sub inc_coverage($$);
sub print_coverage();
sub disable_char($);

$debug = 0;

if ($debug) {
  use Data::Dumper;

  $Data::Dumper::Indent = 1;
  $Data::Dumper::Sortkeys = 1;
  $Data::Dumper::Purity = 1;
}

# map (start dec => ( 'name' => block name, 'end' => end dec, 'coverage' => ( sfd_file => coverage ), 'disabled_count' => number of disabled glyphs )
%blocks = ();
%chars = ();

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
      $blocks{$block_start}{'disabled_count'}++;
      last;
    }
  }
}

sub disable_char_range($$) {
  my ($range_start, $range_end) = @_;

  my $cur_enc = $range_start;
  while ($cur_enc <= $range_end) {
    my $cur_block_start = -1;
    foreach $block_start (keys %blocks) {
      my ($block_end) = $blocks{$block_start}{'end'};
      if (($cur_enc >= $block_start) && ($cur_enc <= $block_end)) {
        $cur_block_start = $block_start;
        last;
      }
    }
    return if ($cur_block_start == -1);
    while (($cur_enc <= $range_end) && ($cur_enc <= $blocks{$cur_block_start}{'end'})) {
      $blocks{$cur_block_start}{'disabled_count'}++;
      $cur_enc++;
    }
  }
}

sub parse_unicode_data_file($) {
  my ($ud_file) = @_;

  open (F, $ud_file) || die "Unable to open $ud_file : $!\n";
  my $prev_enc = -1;
  while (<F>) {
    next if (/^\s*(#|$)/);
    my ($enc, $name) = split (/;/);
    $enc = hex ($enc);
    if ($prev_enc + 1 < $enc) {
      disable_char_range ($prev_enc + 1, $enc - 1);
    }
    disable_char ($enc) if ($name =~ /^</);
    $chars{$enc} = 1 if ($name !~ /^</);
    $prev_enc = $enc;
  }
  # find last possible character
  $last_enc = $prev_enc;
  foreach $block_start (keys %blocks) {
    my ($block_end) = $blocks{$block_start}{'end'};
    $last_enc = $block_end if ($block_end > $last_enc);
  }
  if ($prev_enc + 1 <= $last_enc) {
    disable_char_range ($prev_enc + 1, $last_enc);
  }
  close (F);
}

sub inc_coverage($$) {
  my ($sfd_file, $dec_enc) = @_;
  
  foreach $block_start (keys %blocks) {
    my ($block_end) = $blocks{$block_start}{'end'};
    if (($dec_enc >= $block_start) && ($dec_enc <= $block_end)) {
      if (exists $chars{$dec_enc}) {
        $blocks{$block_start}{'coverage'}{$sfd_file}++;
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
      inc_coverage ($sfd_file, $curenc);
    }
  }
  close (F);
}

# TODO: formats would be better
sub print_coverage() {
  print <<END;
This is the Unicode coverage file for DejaVu fonts
(\$Id\$)

Control and similar characters are discounted from totals.

END
  print "                                                ";
  foreach $sfd_file (@sfd_files) {
    my $label = $sfd_files{$sfd_file};
    printf "%-19s", $label;
  }
  print "\n";
  foreach $block_start (sort { $a <=> $b } keys %blocks) {
    my ($block_end) = $blocks{$block_start}{'end'};
    my ($name) = $blocks{$block_start}{'name'};
    my ($disabled) = $blocks{$block_start}{'disabled_count'};
    $disabled = 0 if (!defined $disabled);
    my ($length) = $block_end - $block_start + 1 - $disabled;
    printf "U+%04x %-40s", $block_start, $name;
    foreach $sfd_file (@sfd_files) {
      my ($coverage) = $blocks{$block_start}{'coverage'}{$sfd_file};
      $coverage = 0 if (!defined $coverage);
      my ($percent) = ($length != 0) ? ($coverage/$length * 100) : 0;
      if ($percent > 0) {
        printf " %3d%%", $percent;
      } else {
        print "     ";
      }
      printf " %-13s", "($coverage/$length)";
    }
    print "\n";
  }
}

if (@ARGV < 3) {
  print STDERR "usage: unicode_data_file blocks_file sfd_file1 label1 (sfd_file2 label2...)\n";
  exit 1;
}

$unicode_data_file = shift @ARGV;
$blocks_file = shift @ARGV;
@sfd_files = ();
%sfd_files = ();
while (@ARGV) {
  $sfd_file = shift @ARGV;
  $label = shift @ARGV;
  push (@sfd_files, $sfd_file);
  $sfd_files{$sfd_file} = $label;
}

parse_blocks_file($blocks_file);
parse_unicode_data_file($unicode_data_file);
foreach $sfd_file (@sfd_files) {
  parse_sfd_file($sfd_file);
}
print_coverage();

if ($debug) {
  print STDERR Data::Dumper->Dump([\%blocks], ['*blocks']);
}

1;
