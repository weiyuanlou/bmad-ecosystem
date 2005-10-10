#!/usr/bin/perl

use File::Find;

$found_one = 0;

find (\&searchit, '/home/dcs/new_lib/bmad/modules');

#foreach $module (keys %table) {
#  print "\n$module\n"; 
#  foreach $used (keys %{$table{$module}}) {
#    print "   $used\n";
#  }
#} 


%modules = map {$_, 0} keys %table;

for ($i = 1; $i <= 20; $i++) {
  foreach $module (keys %table) {
    foreach $used (keys %{$table{$module}}) {
      if (exists $modules{$used}) {
        if ($modules{$module} < $modules{$used} + 1) {
          $modules{$module} = $modules{$used} + 1;
        }
      }
    }
  } 
}

print "\n!-------------------------------------------\n";

for ($i = 0; $i <= 20; $i++) {
  while (($k, $v) = each %modules) {
    if ($v == $i) {
      printf "\nModule: %-22s Level: %i\n", $k, $v;
      foreach $used (keys %{$table{$k}}) {
        print "   $used\n";
      }
    } 
  }
}




#---------------------------------------------------------

sub searchit {

  if (!/\.f90$/) {return;}

  $file = $_;

  $module = $file;
  $module =~ s/\.f90//;

#  print "\nFile: $_\n";

  open (F_IN, $_) || die ("Cannot open File: $_");

  @names = ();

  while (<F_IN>) {
    if (/^ *use */) {
      $name = $';
      chomp $name;
      $name =~ s/,.*//;
      push @names, $name;
#      print "  $name";
    }
    if (/ *contains/) {last;}
  }

  close (F_IN);

  $_ = $file;

  $hash_ptr = {};
  %{$hash_ptr} = map {$_, $_} @names;
  $table{$module} = $hash_ptr;

#  foreach $name (keys %{$hash_ptr}) {
#    print "   $name\n";
#  }

}
