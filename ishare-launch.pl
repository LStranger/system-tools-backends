#!/usr/bin/env perl
$|;
#-*- Mode: perl; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

# Internet Shares Configuration Launcher.
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

# -- Global variables --#

my @echo;
my @modprobe;
my @ipchains;

# -- Parse data -- #

open CFGFILE, "internet-share.cfg";

my @xml_source = <CFGFILE>;

sub parse_head_tags # (array, endtag)
{
  my ($xml_array) = @_;
  my @xml_array = @{$xml_array};

  while (@xml_array) {
    my $line = $xml_array[0]; shift @xml_array;

    ## single start tags
    ## FIXME: Handle multiple lines
    if ($line =~ /^[ \t]*<([\w-]+)([^>]*)?(\/)?>[ \t]*$/) {
      &evaluate (\@xml_array, $1, $2);
    }
  }
}

sub parse_container_content # (array, endtag)
{
  my ($xml_array, $endtag) = @_;
  my @xml_array = @{$xml_array};
  my %data = (); my $data;

  while (@xml_array) {
    my $line = $xml_array[0]; shift @xml_array;
    
    ## single tags
    ## FIXME: Handle multiple lines
    if ($line =~ /^[ \t]*<(\w+)([^>]*)>([^<]*)<\/\1>[ \t]*$/) {
      $data = "$3";
      $data =~ s/.*='([^']*)'.*/$1/;

      if ($data{$1} ne "") {
        $data{$1} = "$data{$1}, $data";
      } else {
        $data{$1} = $data;
      }
    }
    if ($line =~ /<\/$endtag>/) { last; }
  }
  return \%data;
}

sub evaluate # (xml_array, name, attributes, pcdata)
{
  my ($xml_array, $name, $attr, $recur) = @_;
  my @xml_array = @{$xml_array}; 

  if ($name eq "quake")      { &parse_modprobe (\@xml_array, "quake", $attr); }
  if ($name eq "raudio")     { &parse_modprobe (\@xml_array, "raudio", $attr); }  
  if ($name eq "ftp")        { &parse_modprobe (\@xml_array, "ftp", $attr); }

  if ($name eq "ip_forward") { &parse_echo  ("ip_forward", $attr); }

  if ($name eq "timeout")    { &parse_timeout (\@xml_array); }
  if ($name eq "forward")    { &parse_forward (\@xml_array); }
}

sub parse_forward #
{
  my ($xml_array) = @_;
  my @xml_array = @{$xml_array};
  my ($address, $option); 

  while (@xml_array) {
    my $line = $xml_array[0]; shift @xml_array;

    if ($line =~ /<\/formard>/) { last; }
    if ($line =~ /<(ip_address) type='([^']*)'>([0-9.\/]*)<\/\1>/) {
       $address = $3; $option = $2;
       $option =~ s/(.*)/\U$1\E/;
       push @ipchains, "/sbin/ipchains -A forward -s $address -j $option";
    }
  }
}

sub parse_echo # 
{
  my ($option, $attr) = @_;

  $attr =~ s/.*state='([^']*)'.*/$1/;
  
  $value = &parse_boolean ($attr);

  push @echo, "echo \"$value\" > /proc/sys/net/ipv4/$option";
}

sub parse_timeout #
{
  my ($xml_array) = @_;
  my @xml_array = @{$xml_array};
  my %time;
 
  $time = &parse_container_content (\@xml_array, $module);
  %time = %{$time};
    
  push @ipchains, "/sbin/ipchains -M -S $time{tcp} $time{tcpfin} $time{udp}";
}

sub parse_modprobe # (xml_array, module, attr, recur)
{
  my ($xml_array, $module, $attr) = @_;
  my @xml_array = @{$xml_array};
  my ($value, %ports);

  $attr =~ s/.*state='([^']*)'.*/$1/;

  $value = &parse_boolean ($attr);

  $ports = &parse_container_content (\@xml_array, $module);
  %ports = %{$ports};

  push @modprobe, "/sbin/modprobe ip_masq_$module $ports{port}" if ($value == 1);
}

sub exec_from_array # (array)
{
  my (@array) = @_;

  foreach $command (@array) {
    print "Execution $command\n";
    system("$command");
  }
}

sub parse_boolean # (string)
{
  my ($string) = @_;

  if ($string eq "true") {
    return 1; 
  } else { 
    return 0;
  }
}

# -- Main -- #

&parse_head_tags (\@xml_source);

## execute in right order
&exec_from_array (@echo);
&exec_from_array (@modprobe);
&exec_from_array (@ipchains);
