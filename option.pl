#!/usr/bin/env perl 
#-*- Mode: perl; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

# GNU libperl shared libraries for Perl (Option package).
#
# Copyright (C) 2000-2001 Free Software Foundation
#
# Authors: Kenneth Christiansen <kenneth@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.

sub str_format # (string, size)
{
  my ($string, $size) = @_;
  my @char = unpack ('C*', $string);
  $size = $size-$#char;

  for ($i = 0; $i < $size; $i++){
    $string = "$string ";
  }
  return $string;
}


# get_options takes two hashes and the name of the
# program. One hash is build up of arrays with info of: 
# [0] sub to run, [1] shortcut, [2] help info, [3] array
# with sub arguments.
#
# If there in [0] is written "VAR", then the variable in
# [3] will be set to 1 (ie. true).
#
# The second hash includes shortcuts associated with the 
# subs declaired in the first hash.
# 
# If $ARGV is empty the &msg_no_option message is shown.
# If an argument is not in the first hash the message
# &msg_invalid_option is shown.
#
# All other arguments that are not options (ie. starting
# with - or -- are returned by the get_options function 

sub get_options # (string of appname, hashref of options, hashref of shortcut)
{
  ($program, $options, $shortcuts) = @_;
  my %options  = %{$options};
  my %shortcuts = %{$shortcuts};
  my (@files, @args, $func, $opt, $tmp); 
    
  if ($#ARGV < 0) { 
    &msg_option_none ($program);
    exit;
  }
    
  foreach $arg (@ARGV) {

    ## check if it is an option
    if ($arg =~ /^-+(.*)$/) {
      $opt = $1;

      ## check for legal single char options
      if ($opt =~ /^(\w)$/) {
        $tmp = "$shortcuts{$1}";
        $opt = $tmp if ($tmp ne "");
      }

      if ($options{$opt}) {
        my ($method, $argv) = @{$options{$opt}}[0,3];
      
        if ($method eq "VAR") {
          ${$argv} = 1; ## setting variable to true
          next;
        }
        elsif ($func eq ""){
          @args = @{$argv};
          $func = "$method";
        }
      }
      else {
        &msg_option_invalid ($program, $opt);
      } 
    }
    else {
      push @files, $arg;
    }
  }
  &$func(@args) if ($func); ## execute sub associated with option
  return @files;
}  

sub file_open_stringbuffer # (file)
{
  my ($file) = @_;

  local (*FILE);
  local $/; # slurp mode
  open (FILE, "<$file") || die "can't open $file: $!";
  return <FILE>;
}

# -- Messages -- #

sub msg_about # (program, release, copyright, author, year)
{
  my ($program, $version, $copyright, $author, $year) = @_;

  ## Print version information
  if ($#_ < 4) { 
    print STRERR "WARNING: Not enought arguments given to function\n"; 
  }
  else {
    print  "$program $version\n"; 
    printf "Written by %s, %s.\n\nCopyright (C) %s, %s \n", $author, $year, $year, $copyright;
    print  "This is free software; see the source for copying conditions.  There is NO\n";
    print  "warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n";
  }
  exit;
}

sub msg_option_none # (prog_name)
{
  my ($program) = @_;
    
  ## Handle invalid arguments
  printf "%s: missing arguments\n", $program;
  exit 1;
}

sub msg_option_invalid # (prog_name, option)
{
  my ($program, $option) = @_;
    
  ## Handle invalid arguments
  printf ("%s: invalid option -- %s\n", $program, $option);
  printf ("Try '%s --help' for more information.\n", $program);
  exit 1;
}

sub msg_help
{
  my ($program, $usage, $desc, $author, $extra, $options) = @_;
  my %options = %{$options};

  ## Print usage information
  print "Usage: $program $usage\n$desc\n\n";

  foreach $line (keys %options) {
    my ($tmp, $shortcut, $info) = @{$options{$line}};

    if ($shortcut eq "") {
      print "       --"; 
    } else { 
      print "  -$shortcut,  --";
    }

    print str_format($line, 25) . "$info\n";     
  }
  
  print "$extra\n" . "Report bugs to $author.\n";
  exit;
}

1;
