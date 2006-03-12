#!/usr/bin/perl -w

# $Id$

# language coverage analyzator
# (c)2006 Stepan Roh
# usage: ./langcover.pl fc-lang_dir sfd_file1 label1 (sfd_file2 label2...)
#  files from http://webcvs.freedesktop.org/fontconfig/fontconfig/fc-lang/ should be downloaded to fc-lang directory

use FileHandle;

sub parse_fc_lang_dir($);
sub parse_orth_file($;$);
sub parse_sfd_file($);
sub inc_coverage($$);
sub print_coverage();

# map (language code => ( 'name' => name, 'chars' => list of glyphs, 'coverage' => ( sfd_file => coverage ) )
%langs = ();

sub parse_fc_lang_dir($) {
  my ($fc_lang_dir) = @_;
  
  opendir(DIR, $fc_lang_dir) || die "Unable to open $fc_lang_dir : $!\n";
  my @orth_files = map { "$fc_lang_dir/$_" } grep { /\.orth$/ } readdir(DIR);
  closedir(DIR);
  
  foreach $orth_file (@orth_files) {
    parse_orth_file($orth_file);
  }
}

# missing or UTF-8 lang names
%lang_names = (
  'gn' => 'Guarani',
  'ja' => 'Japanese',
  'nb' => 'Norwegian Bokmal',
  'no' => 'Norwegian (Bokmal)',
  'se' => 'North Sami',
  'sma' => 'South Sami',
  'smj' => 'Lule Sami',
  'smn' => 'Inari Sami',
  'sms' => 'Skolt Sami',
  'vo' => 'Volapuk',
  'zh-tw' => 'Chinese (traditional)',
);

sub parse_orth_file($;$) {
  my ($orth_file, $lang) = @_;

  if (!defined $lang) {
    ($lang) = ($orth_file =~ m,/(.*)\.,);
    $lang =~ tr/_/-/;
  }
  # XXX some names in orth files have different language codes
  my $orth_lang = $lang;
  $orth_lang = 'kw' if ($orth_lang eq 'ay');
  $orth_lang = 'kw' if ($orth_lang eq 'fj');
  $orth_lang = 'eth' if ($orth_lang eq 'gez');
  $orth_lang = 'hi' if ($orth_lang eq 'pa');
  $orth_lang = 'cu' if ($orth_lang eq 'sco');
  $orth_lang = 'af' if ($orth_lang eq 'sm');
  $orth_lang = 'smj' if ($orth_lang eq 'sms');
  $orth_lang = 'ge' if ($orth_lang eq 'te');
  if (exists($lang_names{$lang})) {
    $langs{$lang}{'name'} = $lang_names{$lang};
  }
  my $f = new FileHandle($orth_file) || die "Unable to open $orth_file : $!\n";
  while (<$f>) {
    if (!exists($langs{$lang}{'name'})) {
      if  (/^#\s*(.*?)\s*\($lang\)/i) {
        $langs{$lang}{'name'} = $1;
        next;
      }
      if (/^#\s*(.*?)\s*\($orth_lang\)/i) {
        $langs{$lang}{'name'} = $1;
        next;
      }
    }
    next if (/^\s*(#|$)/);
    if (/^\s*include\s+(\S+)/) {
      my $include = $1;
      my $include_file;
      ($include_file = $orth_file) =~ s,/[^/]+$,/$include,;
      parse_orth_file($include_file, $lang);
      next;
    }
    my ($start) = ($_ =~ /^\s*(\S+)/);
    if ($lang eq 'ibo') {
      # XXX ibo.orth 1ee1 -> 1ee4 (https://bugs.freedesktop.org/show_bug.cgi?id=6237)
      $start = '1ee4' if ($start eq '1ee1');
    }
    my $end = $start;
    if ($start =~ /-/) {
      ($start, $end) = split(/-/, $start);
    }
    # XXX ab.orth 0re1 -> 04e1 (https://bugs.freedesktop.org/show_bug.cgi?id=6238)
    $end = '04e1' if ($end eq '0re1');
    $start = hex ($start);
    $end = hex ($end);
    for (my $dec_enc = $start; $dec_enc <= $end; $dec_enc++) {
      $langs{$lang}{'chars'}{$dec_enc} = 1;
    }
  }
  $f->close();
}

sub inc_coverage($$) {
  my ($sfd_file, $dec_enc) = @_;
  
  foreach $lang (keys %langs) {
    if (exists $langs{$lang}{'chars'}{$dec_enc}) {
      $langs{$lang}{'coverage'}{$sfd_file}++;
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
This is the language coverage file for DejaVu fonts
(\$Id\$)

END
  print "                                                ";
  foreach $sfd_file (@sfd_files) {
    my $label = $sfd_files{$sfd_file};
    printf "%-19s", $label;
  }
  print "\n";
  foreach $lang (sort keys %langs) {
    my $name = $langs{$lang}{'name'};
    my $length = keys %{$langs{$lang}{'chars'}};
    printf "%-6s %-40s", $lang, $name;
    foreach $sfd_file (@sfd_files) {
      my ($coverage) = $langs{$lang}{'coverage'}{$sfd_file};
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
  print STDERR "usage: fc-lang_dir sfd_file1 label1 (sfd_file2 label2...)\n";
  exit 1;
}

$fc_lang_dir = shift @ARGV;
@sfd_files = ();
%sfd_files = ();
while (@ARGV) {
  $sfd_file = shift @ARGV;
  $label = shift @ARGV;
  push (@sfd_files, $sfd_file);
  $sfd_files{$sfd_file} = $label;
}

parse_fc_lang_dir($fc_lang_dir);
foreach $sfd_file (@sfd_files) {
  parse_sfd_file($sfd_file);
}
print_coverage();

1;
