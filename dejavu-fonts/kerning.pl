#!/usr/bin/perl -w

# $Id$

%chardata = ();
%encmap = ();

$in_char = '';
while (<STDIN>) {
  chomp ($_);
  if (/^([^:]+):\s*(.*)$/) {
    my ($name, $value) = ($1, $2);
    $name = lc ($name);
    if ($name eq 'startchar') {
      $in_char = $value;
    }
    next if (!$in_char);
    if ($name eq 'encoding') {
      my ($enc) = split (/\s+/, $value, 2);
      $encmap{$enc} = $in_char;
      $chardata{$in_char}{'_enc'} = $enc;
    }
    $chardata{$in_char}{$name} = $value;
  }
}

$asked_char = $ARGV[0];
$asked_char = '' if (!defined $asked_char);
$right_kern = '';
$left_kern = '';

foreach $enc (sort { $a <=> $b } keys %encmap) {
  my $char = $encmap{$enc};
  printf '%-16s %5d', $char, $enc;
  print ' kerning:';
  my $kern = $chardata{$char}{'kernsslifo'};
  if ($kern) {
    my @kern = split (/\s+/, $kern);
    my $kern_str;
    for (my $i = 0; $i < @kern; $i += 4) {
      my $kern_char = $encmap{$kern[$i]};
      $kern_str .= ' ' . $kern_char . '[' . sprintf('%x', $kern[$i]) . '] (' . $kern[$i+1] . ')';
      if ($asked_char eq $kern_char) {
        $left_kern .= ' ' . $char . '[' . sprintf('%x', $enc) . '] (' . $kern[$i+1] . ')';
      }
    }
    print $kern_str;
    if ($asked_char eq $char) {
      $right_kern = $kern_str;
    }
  }
  print "\n";
}

if ($asked_char) {
  print "\n";
  print $asked_char, "\n";
  print "right kern chars:", $right_kern, "\n";
  print " left kern chars:", $left_kern, "\n";
}

1;
