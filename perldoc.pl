#!/usr/bin/env perl
#-*- Mode: perl; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

# The Perl Documenter.
#
# Copyright (C) 2000-2001 Ximian, Inc.
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


require "/usr/share/ximian-setup-tools/scripts/general.pl";
require "/usr/share/ximian-setup-tools/scripts/util.pl";
require "/usr/share/ximian-setup-tools/scripts/file.pl";
require "./option.pl";

# -- Release information -- #

my $program  = "perldoc";
my $version  = "0.1";

# -- Global variables -- #

my ($arg_comment, $arg_hide);

# -- Option handeling -- #

my %options = ();
my %shortcuts = ();

my @about_helper = ($program, $version, "Free Software Foundation", 
                  "Kenneth Christiansen <kenneth\@gnu.org>", "2001");

my @help_helper = ($program, "[OPTIONS] ...[REGEX]", 
                 "A JavaDoc like system for Perl.",
                 "<kenneth\@gnu.org>", "", \%options);

%options =
(
 help        => ["msg_help", "H", "shows the help information", \@help_helper],
 version     => ["msg_about", "V", "shows version information", \@about_helper],
 comment     => ["VAR", "", "show comments associated to sub", \$arg_comment],
 hide	     => ["VAR", "", "hide subs without arg description", \$arg_hide],
);

%shortcuts = (H => "help", V => "version");  

# -- Misc Methods -- #

sub print_underscore # string
{
  my ($string) = @_;

  my @char = unpack ('C*', $string);
  my ($size, $line, $i);
  $size = $#char+1;

  for ($i = 0; $i < $size; $i++)
  {
    $line = "$line-";
  }
  return "$string\n$line\n";
}


sub find_desc # array of files -> hash
{
  my %hash = ();
  my $comment;
  my $spaceln_cnt = 0;
 
  foreach my $file (@_) {
    open BUFF, $file;

    foreach $i (<BUFF>)
    {
      if ($spaceln_cnt == 2) 
      {
        $comment = "";
      }
      if ($i =~ /^# ([^--].*)$/) 
      {
        $comment = "$comment  $1\n";
 	$comment =~ s/[ \t]*$//;
      }
      elsif ($i =~ /^sub (\w+)[ \t]*#[ \t]*(.*)$/) 
      {
        $name = $1;
        $info = $2;
        $info =~ s/^\((.*)\)$/$1/;
 
        $hash{"$file;$name"} = ["($info)", $comment];
      }
      elsif ($i =~ /^sub (\w+)/)
      {
        $name = $1;
        if (!$arg_hide) {
          $hash{"$file;$name"} = ["NO DESCRIPTION AVAILABLE", $comment];
 	}
      }
      elsif ($i =~ /^\n/) 
      {
        $spaceln_cnt++;
      }
      else
      {
        $comment = "";
      }
    }
  }
  return %hash;
}

sub manage_args 
{
  if ($ARGV[0] eq "") {
    print "Usage: ./perldoc.pl [REGEX]\n\n";
  }

  foreach my $i (@ARGV) {
    if ($i =~ /^--comment/) { $arg_comment = 1; }
    if ($i =~ /^--hide/)    { $arg_hide    = 1; }
  }
} 

sub print_perldoc
{
  my ($regex) = @_;

  my %hash = &find_desc (<*.pl*>);
  my $filename;

  foreach my $i (sort keys %hash) {
    my ($file, $type);
    my ($info, $comment) = @{$hash{$i}};

    ($file, $method) = split (/;/, $i);  

    $regex =~ s/^\"(.*)\"$/$1/;

    if ($method =~ /$regex/) 
    {
      if ($filename ne $file) 
      {
        print &print_underscore("$file");
        $filename = $file;
      }  

      print "$method $info\n";

      if ($comment ne "")
      { 
        print "$comment\n" if ($arg_comment);
      }
    }
  }
}

# -- Main -- #

my @non_options = &get_options($program, \%options, \%shortcuts);

&print_perldoc($non_options[0]);
