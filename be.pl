#!/usr/bin/env perl
#-*-perl-*-

# Common stuff for the helix-setup-tools backends.
#
# Copyright (C) 2000 Helix Code, Inc.
#
# Authors: Hans Petter Jansson <hpj@helixcode.com>
#          Arturo Espinosa <arturo@helixcode.com>
#          Michael Vogt <mvo@debian.org> - Debian 2.[2|3] support.
#          David Lee Ludwig <davidl@wpi.edu> - Debian 2.[2|3] support.
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


# --- Generic part of usage text --- #

my $be_usage_generic =<<"end_of_usage_generic;";
       Major operations (specify one of these):

       -g --get      Prints the current configuration to standard output, as
                     a standalone XML document. The configuration is read from
                     the host\'s system config files.

       -s --set      Updates the current configuration from a standalone XML
                     document read from standard input. The format is the same
                     as for the document generated with --get.

       -f --filter   Reads XML configuration from standard input, parses it,
                     and writes the configurator\'s impression of it back to
                     standard output. Good for debugging and parsing tests.

       -h --help     Prints this page to standard error.

          --version  Prints version information to standard output.

       Modifiers (specify any combination of these):

          --disable-immediate  With --set, prevents the configurator from
                     running any commands that make immediate changes to
                     the system configuration. Use with --prefix to make a
                     dry run that won\'t affect your configuration.

                     With --get, suppresses running of non-vital external
                     programs that might take a long time to finish.

       -p --prefix <location>  Specifies a directory prefix where the
                     configuration is looked for or stored. When storing
                     (with --set), directories and files may be created.

          --progress Prints machine-readable progress information to standard
                     output, before any XML, consisting of three-digit
                     percentages always starting with \'0\'.

          --report   Prints machine-readable diagnostic messages to standard
                     output, before any XML. Each message has a unique
                     three-digit ID. The report ends in a blank line.

       -v --verbose  Prints human-readable diagnostic messages to standard
                     error.
end_of_usage_generic;


# --- Auto-informative printing --- #


sub be_print_usage
{
  my $i;

  print STDERR "Usage: $be_name-conf <--get | --set | --filter | --help | --version>\n";

  for ($i = (length $be_name); $i > 0; $i--) { print STDERR " "; }
  print STDERR "             [--disable-immediate] [--prefix <location>]\n";

  for ($i = (length $be_name); $i > 0; $i--) { print STDERR " "; }
  print STDERR "             [--progress] [--report] [--verbose]\n\n";

  print STDERR $be_description . "\n";

  print STDERR $be_usage_generic . "\n";
}

sub be_print_version
{
  print "$be_name $be_version\n";
}


# --- Paths to config files --- #


# We list each config file type with as many alternate locations as possible.
# They are tried in array order. First found = used.

@hosts_names =              ( "/etc/hosts" );               # (all)
@sysconfig_network_names =  ( "/etc/sysconfig/network" );   # Red Hat
@rc_config_names =          ( "/etc/rc.config" );           # SuSE
@network_interfaces_names = ( "/etc/network/interfaces" );  # Debian
@network_options_names =    ( "/etc/network/options" );     # Debian


# --- Operation modifying variables --- #

# Variables are set to their default value, which may be overridden by user. Note
# that a $prefix of "" will cause the configurator to use '/' as the base path,
# and disables creation of directories and writing of previously non-existent
# files.


$be_name = "";       # Short name of tool.
$be_version = "";    # Version of tool - [major.minor.revision].
$be_operation = "";  # Major operation user wants to perform - [get | set | filter].

$be_prefix = "";
$be_verbose = 0;
$be_do_immediate = 1;

# For debugging (perl -d) purposes. set to "" for normal operation:
$be_input_file = "";


# --- Progress printing --- #


$be_progress_current = 0;  # Compat with old $progress_max use.
$be_progress_last_percentage = 0;

sub be_progress
{
  $prc = @_[0];

  if ($prc < $be_progress_last_percentage)
  {
    # Don't go backwards.
    $prc = $be_progress_last_percentage;
  }

  if ($prc >= 100)
  {
    # Don't go above 99%.
    $prc = 99;
  }

  if ($be_progress) { printf "%03d percent done.\n", $prc; }

  $be_progress_last_percentage = $prc;
}

sub be_progress_begin { be_progress(0); }

sub be_progress_end { be_progress(99); }

sub be_print_progress  # Compat with old $progress_max use.
{
  my $prc;

  $be_progress_current++;
  be_progress(($be_progress_current * 100) / $progress_max);
}


# --- Report printing --- #


sub be_report
{
  if ($be_reporting)
  {
    printf "%1d%02d %s.\n", @_[0], @_[1], @_[2];
  }
}

sub be_report_begin
{
  be_report(1, 00, "Start of work report");
}

sub be_report_end
{
  be_report(1, 01, "End of work report");
  if ($be_reporting) { print "\n"; }
}

sub be_report_info
{
  if ($be_verbose)
  {
    printf STDERR "%s.\n", @_[1];
  }

  be_report(2, @_[0], @_[1]);
}

sub be_report_warning
{
  if ($be_verbose)
  {
    printf STDERR "Warning: %s.\n", @_[1];
  }

  be_report(3, @_[0], @_[1]);
}

sub be_report_error
{
  if ($be_verbose)
  {
    printf STDERR "Error: %s.\n", @_[1];
  }

  be_report(4, @_[0], @_[1]);
}

sub be_report_fatal
{
  if ($be_verbose)
  {
    printf STDERR "Fatal error: %s.\n", @_[1];
  }

  be_report(5, @_[0], @_[1]);
}


# --- XML print formatting  --- #

# be_xml_enter: Call after entering a block. Increases indent level.
# be_xml_leave: Call before leaving a block. Decreases indent level.
# be_xml_indent: Call before printing a line. Indents to current level. 
# be_xml_vspace: Ensures there is a vertical space of one and only one line.
# be_xml_print: Indent, then print all arguments. Just for sugar.


$be_indent_level = 0;
$be_have_vspace = 0;

sub be_xml_enter  { $be_indent_level += 2; }
sub be_xml_leave  { $be_indent_level -= 2; }
sub be_xml_indent { for ($i = 0; $i < $be_indent_level; $i++) { print " "; } $be_have_vspace = 0; }
sub be_xml_vspace { if (not $be_have_vspace) { print "\n"; $be_have_vspace = 1; } }
sub be_xml_print { &be_xml_indent; print @_; }


# --- XML scanning --- #


# This code tries to replace XML::Parser scanning from stdin in tree mode.

sub be_xml_scan_make_kid_array
  {
    my %hash = {};
    my @sublist;
    
    @attr = $_[0] =~ /[^\t\n\r ]+[\t\n\r ]*([a-zA-Z_-]+)[ \t\n\r]*\=[ \t\n\r\"\']*([a-zA-Z_-]+)/g;
    %hash = @attr;
    
    push(@sublist, \%hash);
    return(\@sublist);
  }


sub be_xml_scan_recurse
{
  my @list;
  if (@_) { @list = $_[0]->[0]; }
  
  while (@be_xml_scan_list)
  {
    $el = $be_xml_scan_list[0]; shift @be_xml_scan_list;

    if (($el eq "") || $el =~ /^\<[!?].*\>$/s) { next; }  # Empty strings, PI and DTD must go.
    if ($el =~ /^\<.*\/\>$/s)  # Empty.
    {
      $el =~ /^\<([a-zA-Z_-]+).*\/\>$/s;
      push(@list, $1);
      push(@list, be_xml_scan_make_kid_array($el));
    }
    elsif ($el =~ /^\<\/.*\>$/s)  # End.
    {
      last;
    }
    elsif ($el =~ /^\<.*\>$/s)  # Start.
    {
      $el =~ /^\<([a-zA-Z_-]+).*\>$/s;
      push(@list, $1);
      $sublist = be_xml_scan_make_kid_array($el);
      push(@list, be_xml_scan_recurse($sublist));
      next;
    }
    elsif ($el ne "")  # PCDATA.
    {
      push(@list, 0);
      push(@list, "$el");
    }
  }
	 
  return(\@list);
}


sub be_xml_scan
  {
    my $doc; my @tree; my $i;
		
    if ($be_input_file eq "") 
    {
      $doc .= $i while ($i = <STDIN>);
    }
    else
    {
      open INPUT_FILE, $be_input_file;
      $doc .= $i while ($i = <INPUT_FILE>);
      close INPUT_FILE;
    }

    @be_xml_scan_list = ($doc =~ /([^\<]*)(\<[^\>]*\>)[ \t\n\r]*/mg); # pcdata, tag, pcdata, tag, ...
    
    $tree = be_xml_scan_recurse;
    
    return($tree);
  }


@be_xml_entities = ( "&lt;", '<', "&gt;", '>', "&apos;", '\\\'', "&quot;", '"' );

sub be_xml_entities_to_plain
  {
    my $in = $_[0];
    my $out = "";
    my @xe;
    
    $in = $$in;
    
    my @elist = ($in =~ /([^&]*)(\&[a-zA-Z_-]+\;)?/mg); # text, entity, text, entity, ...
    
    while (@elist)
      {
	# Join text.
	
	$out = join('', $out, $elist[0]);
	shift @elist;
	
	# Find entity and join its text equivalent.
	# Unknown entities are simply removed.
	
	for (@xe = @be_xml_entities; @xe; )
	  {
	    if ($xe[0] eq $elist[0]) { $out = join('', $out, $xe[1]); last; }
	    shift @xe; shift @xe;
	  }
	
	shift @elist;
      }
    
    return($out);
  }


sub be_xml_plain_to_entities
  {
    my $in = $_[0];
    my $out = "";
    my @xe;
    my $joined = 0;
    
    $in = $$in;
    
    my @clist = split(//, $in);
    
    while (@clist)
      {
	# Find character and join its entity equivalent.
	# If none found, simply join the character.
	
	$joined = 0;		# Cumbersome.
	
	for (@xe = @be_xml_entities; @xe && !$joined; )
	  {
	    if ($xe[1] eq $clist[0]) { $out = join('', $out, $xe[0]); $joined = 1; }
	    shift @xe; shift @xe;
	  }
	
	if (!$joined) { $out = join('', $out, $clist[0]); }
	shift @clist;
      }
    
    return($out);
  }


# --- Utilities for strings, arrays and other data structures --- #


# Boolean <-> strings conversion.

sub be_read_boolean
  {
    if ($_[0] eq "true") { return(1); }
    elsif ($_[0] eq "yes") { return(1); }
    return(0);
  }

sub be_print_boolean_yesno
  {
    if ($_[0] == 1) { return("yes"); }
    return("no");
  }

sub be_print_boolean_truefalse
  {
    if ($_[0] == 1) { return("true"); }
    return("false");
  }


# Pushes a list to an array, only if it's not already in there.
# I'm sure there's a smarter way to do this. Should only be used for small
# lists, as it's O(N^2). Larger lists with unique members should use a hash.

sub be_push_unique
  {
    my $arr = $_[0];
    my $found;
    my $i;
    
    # Go through all elements in pushed list.
    
    for ($i = 1; $_[$i]; $i++)
      {
	# Compare against all elements in destination array.
	
	$found = "";
	for $elem (@$arr)
	  {
	    if ($elem eq $_[$i]) { $found = $elem; last; }
	  }
	
	if ($found eq "") { push(@$arr, $_[$i]); }
      }
  }


sub be_ignore_line
  {
    if (($_[0] =~ /^\#/) || ($_[0] =~ /^[ \t\n\r]*$/)) { return 1; }
    return 0;
  }


# be_item_is_in_list
#
# Given:
#   * A scalar value.
#   * An array.
# this function will return 1 if the scalar value is in the array, 0 otherwise.

sub be_item_is_in_list
{
  my $value = shift(@_);

  foreach my $item (@_)
  {
    if ($value eq $item) { return 1; }
  }

  return 0;
}


# be_get_key_for_subkeys
#
# Given:
#   * A hash-table with its values containing references to other hash-tables,
#     which are called "sub-hash-tables".
#   * A list of possible keys (stored as strings), called the "match_list".
# this method will look through the "sub-keys" (the keys of each
# sub-hash-table) seeing if one of them matches up with an item in the
# match_list.  If so, the key will be returned.

sub be_get_key_for_subkeys
{
  my %hash = %{$_[0]};
  my @match_list = @{$_[1]};

  foreach $key (keys(%hash))
  {
    my %subhash = %{$hash{$key}};
    foreach $item (@match_list)
    {
      if ($subhash{$item} ne "") { return $key; }
    }
  }

  return "";
}


# be_get_key_for_subkey_and_subvalues
#
# Given:
#   * A hash-table with its values containing references to other hash-tables,
#     which are called "sub-hash-tables".  These sub-hash-tables contain
#     "sub-keys" with associated "sub-values".
#   * A sub-key, called the "match_key".
#   * A list of possible sub-values, called the "match_list".
# this function will look through each sub-hash-table looking for an entry
# whose:
#   * sub-key equals match_key.
#   * sub-key associated sub-value is contained in the match_list.

sub be_get_key_for_subkey_and_subvalues
{
  my %hash = %{$_[0]};
  my $key;
  my $match_key = $_[1];
  my @match_list = @{$_[2]};

  foreach $key (keys(%hash))
  {
    my %subhash = %{$hash{$key}};
    my $subvalue = $subhash{$match_key};

    if ($subvalue eq "") { next; }

    foreach $item (@match_list)
    {
      if ($item eq $subvalue) { return $key; }
    }
  }

  return "";
}


# --- IP calculation --- #


# be_ip_calc_network (<IP>, <netmask>)
#
# Calculates the network address and returns it as a string.

sub be_ip_calc_network
{
  my @ip_reg1;
  my @ip_reg2;

  @ip_reg1 = (@_[0] =~ /([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/);
  @ip_reg2 = (@_[1] =~ /([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/);

  @ip_reg1[0] = (@ip_reg1[0] * 1) & (@ip_reg2[0] * 1);
  @ip_reg1[1] = (@ip_reg1[1] * 1) & (@ip_reg2[1] * 1);
  @ip_reg1[2] = (@ip_reg1[2] * 1) & (@ip_reg2[2] * 1);
  @ip_reg1[3] = (@ip_reg1[3] * 1) & (@ip_reg2[3] * 1);

  return(join('.', @ip_reg1));
}


# be_ip_calc_network (<IP>, <netmask>)
#
# Calculates the broadcast address and returns it as a string.

sub be_ip_calc_broadcast
{
  my @ip_reg1;
  my @ip_reg2;
  
  @ip_reg1 = (@_[0] =~ /([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/);
  @ip_reg2 = (@_[1] =~ /([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/);
 
  @ip_reg1 = ($cf_hostip =~ /([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/);

  @ip_reg1[0] = (@ip_reg1[0] * 1) | (~(@ip_reg2[0] * 1) & 255);
  @ip_reg1[1] = (@ip_reg1[1] * 1) | (~(@ip_reg2[1] * 1) & 255);
  @ip_reg1[2] = (@ip_reg1[2] * 1) | (~(@ip_reg2[2] * 1) & 255);
  @ip_reg1[3] = (@ip_reg1[3] * 1) | (~(@ip_reg2[3] * 1) & 255);
  
  return(join('.', @ip_reg1));
}


# --- File operations --- #


# be_locate_tool
#
# Tries to locate a command-line utility from a set of built-in paths
# and a set of user paths (found in the environment). The path (or a negative
# entry) is cached in a hash, to avoid searching for it repeatedly.

@be_builtin_paths = ( "/sbin", "/usr/sbin", "/usr/local/sbin", "/bin",
                      "/usr/bin", "/usr/local/bin" );

%be_tool_paths = {};

sub be_locate_tool
{
  my $found = "";
  my @user_paths;

  $found = %be_tool_paths->{$_[0]};
  if ($found eq "0")
  {
    # Negative cache hit. At this point, the failure has already been reported
    # once.
    return "";
  }

  if ($found eq "")
  {
    # Nothing found in cache. Look for real.

    # Extract user paths to try.

    @user_paths = ($ENV{PATH} =~ /([^:]+):/mg);

    # Try user paths.

    for $path (@user_paths)
    {
      if (-x "$path/$_[0]") { $found = "$path/$_[0]"; last; }
    }

    # Try builtin paths.

    for $path (@be_builtin_paths)
    {
      if (-x "$path/$_[0]") { $found = "$path/$_[0]"; last; }
    }

    # Report success/failure and update cache.

    if ($found)
    {
      %be_tool_paths->{$_[0]} = $found;
      be_report_info(97, "Found $_[0] tool");
    }
    else
    {
      %be_tool_paths->{$_[0]} = "0";
      be_report_warning(96, "Couldn't find $_[0] tool");
    }
  }
  
  return($found);
}


sub be_open_read_from_names
{
  local *FILE;
  my $fname = "";
    
  foreach $name (@_)
  {
    if (open(FILE, "$be_prefix/$name")) { $fname = $name; last; }
  }
  
  (my $fullname = "$be_prefix/$fname") =~ tr/\//\//s;  # '//' -> '/'	

  if ($fname eq "") 
  { 
    be_report_warning(99, "Could not read \[@_\]");
    return;
  }

  be_report_info(99, "Reading options from \[$fullname\]");
  return *FILE;
}


sub be_open_write_from_names
  {
    local *FILE;
    my $name;
    my $fullname;
    
    # Find out where it lives.
    
    for $elem (@_) { if (stat($elem) ne "") { $name = $elem; last; } }
    
    if ($name eq "")
      {
	# If we couldn't locate the file, and have no prefix, give up.
	
	# If we have a prefix, but couldn't locate the file relative to '/',
	# take the first name in the array and let that be created in $prefix.
	
	if ($be_prefix eq "")
	  {
	    be_report_warning(98, "No file to replace: \[@_\]");
	    return(0);
	  }
	else
	  {
	    $name = $_[0];
	    (my $fullname = "$be_prefix/$name") =~ tr/\//\//s;
	    be_report_warning(97, "Could not find \[@_\]. Writing to \[$fullname\]");
	  }
      }
    else
      {
	(my $fullname = "$be_prefix/$name") =~ tr/\//\//s;
	be_report_info(98, "Found \[$name\]. Writing to \[$fullname\]");
      }
    
    ($name = "$be_prefix/$name") =~ tr/\//\//s;  # '//' -> '/' 
      be_create_path($name);
    
    # Make a backup if the file already exists - if the user specified a prefix,
    # it might not.
    
    if (stat($name))
      {
	# NOTE: Might not work everywhere. Might be unsafe if the user is allowed
	# to specify a $name list somehow, in the future.
	
	system("cp $name $name.confsave >/dev/null 2>/dev/null");
      }
    
    # Truncate and return filehandle.
    
    if (!open(FILE, ">$name"))
      {
	be_report_error(99, "Failed to write to \[$name\]");
	return;
      }
    
    return *FILE;
  }


sub be_open_filter_write_from_names
  {
    local *INFILE;
    local *OUTFILE;
    my ($name, $elem);
    
    # Find out where it lives.
    
    for $elem (@_) { if (stat($elem) ne "") { $name = $elem; last; } }
    
    if ($name eq "")
      {
	# If we couldn't locate the file, and have no prefix, give up.
	
	# If we have a prefix, but couldn't locate the file relative to '/',
	# take the first name in the array and let that be created in $prefix.
	
	if ($prefix eq "")
	  {
	    be_report_warning(98, "No file to patch: \[@_\]");
	    return(0, 0);
	  }
	else
	  {
	    $name = $_[0];
	    (my $fullname = "$be_prefix/$name") =~ tr/\//\//s;
	    be_report_warning(97, "Could not find \[@_\]. Patching \[$fullname\]");
	  }
      }
    else
      {
	(my $fullname = "$be_prefix/$name") =~ tr/\//\//s;
	be_report_info(98, "Found \[$name\]. Patching \[$fullname\]");
      }
    
    ($name = "$be_prefix/$name") =~ tr/\//\//s;  # '//' -> '/' 
      be_create_path($name);
    
    # Make a backup if the file already exists - if the user specified a prefix,
    # it might not.
    
    if (stat($name))
      {
	# NOTE: Might not work everywhere. Might be unsafe if the user is allowed
	# to specify a $name list somehow, in the future.
	
	system("cp $name $name.confsave >/dev/null 2>/dev/null");
      }
    
    # Return filehandles. Backup file is used as filter input. It might be
    # invalid, in which case the caller should just write to OUTFILE without
    # bothering with INFILE filtering.
    
    open(INFILE, "$name.confsave");
    
    if (!open(OUTFILE, ">$name"))
      {
	be_report_error(99, "Failed to write to \[$name\]");
	return;
      }
    
    return(*INFILE, *OUTFILE);
  }


sub be_create_path
  {
    my $path;
    
    $path = $_[0];
    my @pelem = split(/\//, $path); # 'a/b/c/d/' -> 'a', 'b', 'c', 'd', ''
    
    for ($path = ""; @pelem; shift @pelem)
      {
	if ($pelem[1] ne "")
	  {
	    $path = "$path$pelem[0]";
	    mkdir($path, 0770);
	    $path = "$path/";
	  }
      }
  }


# --- Command-line utilities --- #


# be_run (<command line>)
#
# Assumes the first word on the command line is the command-line utility
# to run, and tries to locate it, replacing it with its full path. The path
# is cached in a hash, to avoid searching for it repeatedly. Output
# redirection is appended, to make the utility perfectly silent. The
# preprocessed command line is run, and its exit value is returned.
#
# Example: "mkswap /dev/hda3" -> "/sbin/mkswap /dev/hda3 >/dev/null 2>/dev/null".

sub be_run
{
  my ($tool_name, $tool_path, @argline);

  ($tool_name, @argline) = split(/ /, @_[0]);

  $tool_path = be_locate_tool($tool_name);
  if ($tool_path eq "")
  {
    # Not found at all.
    return;
  }

  return(system("$tool_path @argline 2>/dev/null >/dev/null"));
}


# --- Service/daemon utilities --- #


# be_service_enable (<sysv pri>, <args>, <name>, <name>, ...)
#
# Enables a service permanently, using the SYSV scheme if present, and
# more direct means if it is not.
#
# <sysv pri> is the priority (0-99) with which it will be started.
# <args> is the arguments to pass if started directly.
# <name> ... are names to look for in sysv dirs and, failing that, of binaries.

sub be_service_enable
{
  my ($pri, $args, $name, $path, $fullname);

  # Save the SYSV priority as a two-digit string.
  
  $pri = sprintf("%02d", @_[0]);
  shift @_;

  # Save the arguments (to be used in brute approach).

  $args = @_[0];
  shift @_;

  # Look for SYSV files.

  for $coin (@_)
  {
    if (-f "/etc/rc.d/init.d/$coin")
    {
      $path = "/etc/rc.d/init.d/";
      $name = $coin;
      last;
    }
    elsif (-f "/etc/init.d/$coin")
    {
      $path = "/etc/init.d/";
      $name = $coin;
      last;
    }
  }

  # If no SYSV files found, take the brute approach. This won't survive a
  # reboot. Also, it relies on the daemon's reluctance to start multiple
  # instances of itself.

  if ($name eq "")
  {
    for $coin (@_)
    {
      $fullname = be_locate_tool($coin);
      if ($fullname) { last; }
    }

    if ($fullname eq "") { return; }

    system("$fullname $args >/dev/null 2>/dev/null &");
    return 1;
  }

  # Otherwise, do it the SYSV way.
  # TODO: Save return value from system() call.

  system("$path$name start >/dev/null 2>/dev/null");

  # Ensure rc.d start links and remove any kill links in runlevel 3 and 5.

  # This works with the two rc.d locs I know: /etc/rc.d/rcN.d/  /etc/rcN.d/
  # And their corresponding init.d locs:      /etc/rc.d/init.d/ /etc/init.d/

  for $rc_dir ("/etc/rc.d/rc3.d/", "/etc/rc.d/rc5.d/", "/etc/rc3.d/", "/etc/rc5.d/")
  {
    local *RC_DIR;
    my $have_start_link = 0;

    if (!(opendir RC_DIR, $rc_dir)) { next; }

    foreach $link (readdir(RC_DIR))
    {
      if ($link =~ /K[0-9]+$name/)
      {
        unlink("$rc_dir$link");
      }
      elsif ($link =~ /S[0-9]+$name/)
      {
        $have_start_link = 1;
      }
    }
    
    closedir RC_DIR;

    if (!$have_start_link)
    {
      symlink("../init.d/$name", "$rc_dir" . "S$pri$name");
    }
  }
  
  return 1;
}


# be_service_disable (<sysv pri>, <args>, <name>, <name>, ...)
#
# Disables a service permanently, using the SYSV scheme if present, and
# more direct means if it is not.
#
# <sysv pri> is the priority (0-99) with which it will be stopped.
# <args> is the arguments to pass if stopped directly. [NOT USED YET]
# <name> ... are names to look for in sysv dirs and, failing that, of binaries.

sub be_service_disable
{
  my ($pri, $args, $name, $path, $fullname);

  # Save the SYSV priority as a two-digit string.
  
  $pri = sprintf("%02d", @_[0]);
  shift @_;

  # Save the arguments (to be used in brute approach).

  $args = @_[0];
  shift @_;

  # Look for SYSV files.

  for $coin (@_)
  {
    if (-f "/etc/rc.d/init.d/$coin")
    {
      $path = "/etc/rc.d/init.d/";
      $name = $coin;
      last;
    }
    elsif (-f "/etc/init.d/$coin")
    {
      $path = "/etc/init.d/";
      $name = $coin;
      last;
    }
  }

  # If no SYSV files found, take the brute approach. Currently this just
  # leaves the daemon alone. FIXME: Find a reliable way to get the PID and
  # kill it. Remember that "killall" is a bit _too_ radical on some systems.

  if ($name eq "")
  {
#    for $coin (@_)
#    {
#      $fullname = be_locate_tool($coin);
#      if ($fullname) { last; }
#    }
#
#    if ($fullname eq "") { return; }
#
#    system("$fullname $args >/dev/null 2>/dev/null &");
    return 0;
  }

  # Otherwise, do it the SYSV way.
  # TODO: Save return value from system() call.

  system("$path$name stop >/dev/null 2>/dev/null");

  # Ensure rc.d kill links and remove any start links in runlevel 3 and 5.

  # This works with the two rc.d locs I know: /etc/rc.d/rcN.d/  /etc/rcN.d/
  # And their corresponding init.d locs:      /etc/rc.d/init.d/ /etc/init.d/

  for $rc_dir ("/etc/rc.d/rc3.d/", "/etc/rc.d/rc5.d/", "/etc/rc3.d/", "/etc/rc5.d/")
  {
    local *RC_DIR;
    my $have_stop_link = 0;

    if (!(opendir RC_DIR, $rc_dir)) { next; }

    foreach $link (readdir(RC_DIR))
    {
      if ($link =~ /S[0-9]+$name/)
      {
        unlink("$rc_dir$link");
      }
      elsif ($link =~ /K[0-9]+$name/)
      {
        $have_stop_link = 1;
      }
    }
    
    closedir RC_DIR;

    if (!$have_stop_link)
    {
      symlink("../init.d/$name", "$rc_dir" . "K$pri$name");
    }
  }
  
  return 1;
}


# be_service_restart (<sysv pri>, <args>, <name>, <name>, ...)
#
# Enables a service permanently, using the SYSV scheme if present, and
# more direct means if it is not. If already enabled, it is restarted, useful
# e.g. if you want its configuration reloaded.
#
# <sysv pri> is the priority (0-99) with which it will be started.
# <args> is the arguments to pass if started directly.
# <name> ... are names to look for in sysv dirs and, failing that, of binaries.

sub be_service_restart
{
  my ($pri, $args, $name, $path, $fullname);

  # Save the SYSV priority as a two-digit string.
  
  $pri = sprintf("%02d", @_[0]);
  shift @_;

  # Save the arguments (to be used in brute approach).

  $args = @_[0];
  shift @_;

  # Look for SYSV files.

  for $coin (@_)
  {
    if (-f "/etc/rc.d/init.d/$coin")
    {
      $path = "/etc/rc.d/init.d/";
      $name = $coin;
      last;
    }
    elsif (-f "/etc/init.d/$coin")
    {
      $path = "/etc/init.d/";
      $name = $coin;
      last;
    }
  }

  # If no SYSV files found, take the brute approach. This won't survive a
  # reboot. Also, it relies on the daemon's reluctance to start multiple
  # instances of itself. The arguments supplied should make the command send
  # a reload signal to any existing instances.

  if ($name eq "")
  {
    for $coin (@_)
    {
      $fullname = be_locate_tool($coin);
      if ($fullname) { last; }
    }

    if ($fullname eq "") { return; }

    system("$fullname $args >/dev/null 2>/dev/null &");
    return 1;
  }

  # Otherwise, do it the SYSV way.
  # TODO: Save return value from system() call.

  system("$path$name restart >/dev/null 2>/dev/null");

  # Ensure rc.d start links and remove any kill links in runlevel 3 and 5.

  # This works with the two rc.d locs I know: /etc/rc.d/rcN.d/  /etc/rcN.d/
  # And their corresponding init.d locs:      /etc/rc.d/init.d/ /etc/init.d/

  for $rc_dir ("/etc/rc.d/rc3.d/", "/etc/rc.d/rc5.d/", "/etc/rc3.d/", "/etc/rc5.d/")
  {
    local *RC_DIR;
    my $have_start_link = 0;

    if (!(opendir RC_DIR, $rc_dir)) { next; }

    foreach $link (readdir(RC_DIR))
    {
      if ($link =~ /K[0-9]+$name/)
      {
        unlink("$rc_dir$link");
      }
      elsif ($link =~ /S[0-9]+$name/)
      {
        $have_start_link = 1;
      }
    }

    closedir RC_DIR;

    if (!$have_start_link)
    {
      symlink("../init.d/$name", "$rc_dir" . "S$pri$name");
    }
  }

  return 1;
}


# --- Name resolution utilities --- #


# be_ensure_local_host_entry (<hostname>)
#
# Given a hostname, add the hostname as an alias for the loopback IP, in the
# /etc/hosts database. This is required for tools like nmblookup to work on
# a computer with no reverse name or DNS. The name is added as the first alias,
# which usually means it'll be returned by a lookup on the loopback IP.

sub be_ensure_local_host_entry
{
  my $local_ip = "127.0.0.1";
  my $local_hostname = @_[0];
  my ($ifh, $ofh);
  local (*INFILE, *OUTFILE);
  my $written = 0;

  if ($local_hostname eq "") { return; }

  # Find the file.

  ($ifh, $ofh) = be_open_filter_write_from_names(@hosts_names);
  if (!$ofh) { return; }  # We didn't find it.
  *INFILE = $ifh; *OUTFILE = $ofh;

  # Write the file, preserving as much as possible from INFILE.

  while (<INFILE>)
  {
    @line = split(/[ \n\r\t]+/, $_);
    if ($line[0] eq "") { shift @line; }  # Leading whitespace. He.

    if ($line[0] ne "" && (not be_ignore_line($line[0])) &&
#       ($line[0] =~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/) &&
        $line[0] eq $local_ip)
    {
      # Found $local_ip. Add $local_hostname to beginning of list,
      # and remove any other occurrences.

      shift @line;

      printf OUTFILE ("%-16s %s", $local_ip, $local_hostname);
      for $alias (@line)
      {
        if ($alias ne $local_hostname) { print OUTFILE " $alias"; }
      }
      print OUTFILE "\n";

      $written = 1;
    }
    else { print OUTFILE; }
  }

  # If the IP wasn't present, add the entry at the end.

  if (!$written) { printf OUTFILE ("%-16s %s\n", $local_ip, $local_hostname); }
  close INFILE;
  close OUTFILE;
}


# --- Network interface readers --- #

# Example of use:
#
# $nw = be_network_get();
# $ifaces = $$nw{"interfaces"};
#
# if (exists($nw{"global"}->{"forward"})) { print "Forwarding.\n"; }
#
# foreach $key (keys(%{$ifaces}))
# {
#   print $key . " " . $$ifaces{$key}->{address} . " " . $$ifaces{$key}->{netmask} .
#         " " . $$ifaces{$key}->{method} . " " . $$ifaces{$key}->{gateway};
#
#   if (exists($$ifaces{$key}->{primary})) { print "PRIMARY"; }
#   
#   print "\n";
# }

# Debian 2.[2|3]+ style /etc/network/interfaces
#
# <filtered lines>
# iface <interface> inet <static|dhcp|bootp|ppp>
#     address <ip>
#     netmask <ip mask>
#     gateway <gateway ip>
#     broadcast <broadcast ip>
#     network <network ip>
#     noauto (this is only used to not enable the interface on boot)
#     up <command to run when the interface is brought up>
#     down <command to run when the interface is brought down>
# <filtered lines>
# (more interfaces may follow)
#
# A "#" character at the very beginning of a line causes that line to be
# treated as a comment.
# A "\" character at the very end of a line causes that line to continue onto
# the next line.
#
# NOTE: For more information on the format of /etc/network/interfaces, read
# the "interfaces" man page (section 5).  Also be sure to look at the example
# file in /usr/share/doc/netbase/examples/interfaces.  Both of these are
# included as part of the "netbase" package in Debian 2.[2|3].
#
# Exists: Debian 2.[2|3]
#
# Absent:

# Debian 2.[2|3] style /etc/network/options
#
# <filtered lines>
# ip_forward=<yes|no>
# spoofprotect=<yes|no>
# syncookies=<yes|no>
# <filtered lines>
#
# Reads in relevant network options that aren't found in
# /etc/network/interfaces.  NOTE: None of these options are interface specific.
#
# Exists: Debian 2.[2|3]
#
# Absent:

# be_network_get_debian_interfaces

sub be_network_get_debian
{
  my (%nw, %ifaces, $current_name, $current_iface, $fh);

  $fh = be_open_read_from_names(@network_interfaces_names);
  if (not $fh) { return; }

  $nw{"interfaces"} = \%ifaces;

  # Build a list of all interfaces
  while (<$fh>)
  {
    # Split the current line into a list of tokens.
    @line = split(/[ \n\r\t]+/, $_);

    # Remove leading whitespace.
    if ($line[0] eq "") { shift(@line); }

    # Check to see if this line continues onto other lines.  If so, append
    # them
    while ($line[$#line] eq "\\")
    {
      # Remove the \ character.
      pop @line;

      # Read in the next line and split it into a list of tokens.
      @nextline = split(/[ \n\r\t]+/, <FILE>);

      # Remove any leading whitepage.
      if ($nextline[0] eq "") { shift(@nextline); }

      # Append @nextline to the end of @line
      push @line, @nextline;
    }

    # Make sure this line isn't a comment.
    if (be_ignore_line($line[0])) { next; }

    # Check if the line specifies a new interface.
    if ($line[0] eq "iface" && not be_ignore_line($line[1]))
    {
      # Make sure the interface is set up for IPv4/internet networking
      if ($line[2] ne "inet") { next; }

      # Also make sure there is a set configuration method.
      if ($line[3] eq "" || be_ignore_line($line[3]))
      {
        be_report_warning(02, "Warning: Interface $line[1] has no " .
                              "config method");
        next;
      }

      # Create a new hash table for this interface.
      my %iface_hash = ();

      # Set this interface to be the 'current' one.
      $current_name = $line[1];
      $current_iface = $ifaces{$current_name} = \%iface_hash;

      # Set the interface's method
      $$current_iface{"method"} = $line[3];
      
      # Default in Debian is auto (onboot).
      $$current_iface{"auto"} = 1;
    }
    else  # Add an attribute to an already set interface.
    {
      # Make sure an interface has been set.
      if (not $current_iface) { next; }

      # Make sure the attribute isn't empty.
      if (not $line[1]) { next; }

      if ($line[1] eq "noauto") { $$current_iface{"auto"} = 0; }

      # Set the attribute
      $$current_iface{$line[0]} = join(' ', $line[1..$#line]);
    }
  }

  close $fh;

  # Read options.

  my %g;
  $nw{"global"} = \%g;

  $fh = be_open_read_from_names(@network_options_names);
  if (!$fh) { return \%nw; }

  # Build a list of all interfaces
  while (<$fh>)
  {
    # Split the current line into a list of tokens.
    @line = split(/[ \n\r\t=]+/, $_);

    # Remove leading whitespace.
    if ($line[0] eq "") { shift(@line); }

    # Make sure this line isn't a comment.
    if (be_ignore_line($line[0])) { next; }

    # Set any relevant global configuration variables.
    if ($line[0] eq "ip_forward" && not be_ignore_line($line[1]) &&
        be_read_boolean($line[1]))
    {
      $g{"forward"} = 1;
    }
  }

  close ($fh);

  # Select a primary interface.
  
  # - If only one interface exists, use that one.
  # - If an interface has a preset gateway, use that one.
  # - The first interface with a dynamic configuration "method" (such as
  #�  "dhcp", "bootp", "ppp", etc.) will be selected.
  # - If all else fails, pick the first interface.

  # Do any interfaces exist at all?
  if (scalar(keys(%ifaces)) == 0)
  {
    return \%nw;
  }

  # See if only one interface exists.
  elsif (scalar(keys(%ifaces)) == 1)
  {
    $chosen_name = (keys(%ifaces))[0];
  }

  else
  {
    # Look for an interface with a preset gateway.
    $chosen_name = be_get_key_for_subkeys(\%ifaces, ["gateway"]);
    
    # If need be, look for an interface with a dynamic configuration "method".
    if ($chosen_name eq "")
    {
      $chosen_name = be_get_key_for_subkey_and_subvalues(\%ifaces, "method", ["dhcp", "bootp", "ppp"]);
    }

    # If an interface hasn't been chosen, then just pick the first available one.
    if ($chosen_name eq "")
    {
      $chosen_name = (keys(%ifaces))[0];
    }
  }

  %{$ifaces{$chosen_name}}->{"primary"} = 1;

  return \%nw;
}


# Red Hat style /etc/sysconfig/network-scripts/ifcfg-*
#
# <filtered lines>
# IPADDR=<ip>
# NETMASK=<ip mask>
# NETWORK=<network ip>
# BROADCAST=<broadcast ip>
# BOOTPROTO=<bootp|dhcp|none>
# ONBOOT=<boolean>
# <filtered lines>
#
# Determines the configuration of a specific network interface. First
# argument must be the name of the interface.
#
# Exists: Red Hat [5|6].x
#
# Absent:

# Red Hat style /etc/sysconfig/network
#
# <filtered lines>
# NETWORKING=<boolean>
# FORWARD_IPV4=<boolean>
# GATEWAY=<ip>
# GATEWAYDEV=<interface>
# <filtered lines>
#
# Determines the primary network configuration. BEWARE: This is actually a
# sourced shell script. We rely on some lenience from the user (and the distro)
# to be able to parse it correctly.
#
# Exists: Red Hat [5|6].x, Caldera 2.4, TurboLinux 6.0, Mandrake 7.0
#
# Absent: SuSE 6.3, SunOS 5.7

# be_network_get_redhat

sub be_network_get_redhat
{
  local *IFACE_DIR;
  my (%nw, %ifaces, $fh);

  if (!(opendir IFACE_DIR, "/etc/sysconfig/network-scripts")) { return 0; }

  $nw{"interfaces"} = \%ifaces;

  foreach $i (readdir (IFACE_DIR))
  {
    next if not $i =~ /ifcfg-([a-z0-9]+)/;

    $fh = be_open_read_from_names("/etc/sysconfig/network-scripts/$i");
    if (!$fh) { next; }

    # Found an interface file, add another interface hash.

    my %iface_hash;
    my $iface_name = $1;
    my $iface = $ifaces{$iface_name} = \%iface_hash;

    # Parse the file.

    while (<$fh>)
    {
      @line = split(/[ \n\r\t\"\'=]+/, $_);
      if ($line[0] eq "") { shift(@line); }  # Leading whitespace. He.

      if ($line[0] eq "IPADDR" && not be_ignore_line($line[1]))
      {
        $$iface{"address"} = $line[1];
	if (!exists($$iface{"method"})) { $$iface{"method"} = "static"; }
      }
      elsif ($line[0] eq "NETMASK" && not be_ignore_line($line[1]))
      {
        $$iface{"netmask"} = $line[1];
      }
      elsif ($line[0] eq "BOOTPROTO" && not be_ignore_line($line[1]))
      {
        if ($line[1] eq "bootp")   { $$iface{"method"} = "bootp"; }
        elsif ($line[1] eq "dhcp") { $$iface{"method"} = "dhcp"; }
      }
      elsif ($line[0] eq "ONBOOT" && not be_ignore_line($line[1]))
      {
        if (be_read_boolean($line[1]))
	{
	  $$iface{"auto"} = 1;  # Set the auto flag.
	}
      }
    }

    close ($fh);
  }

  closedir (IFACE_DIR);

  # Read options.

  my (%g, $gateway_dev);
  $nw{"global"} = \%g;

  $fh = be_open_read_from_names(@sysconfig_network_names);
  if (!$fh) { return \%nw; }  # We didn't find it.

  # Parse the file.

  while (<$fh>)
  {
    @line = split(/[ \n\r\t\"\'=]+/, $_);
    if ($line[0] eq "") { shift(@line); }  # Leading whitespace. He.

    if ($line[0] eq "NETWORKING" && !be_ignore_line($line[1]) &&
        be_read_boolean($line[1]))
    {
      $g{"auto"} = 1;
    }
    elsif ($line[0] eq "FORWARD_IPV4" && !be_ignore_line($line[1]) &&
           be_read_boolean($line[1]) == 1)
    {
      $g{"forward"} = 1;
    }
    elsif ($line[0] eq "GATEWAY" && !be_ignore_line($line[1]))
    {
      $g{"gateway"} = $line[1];
    }
    elsif ($line[0] eq "GATEWAYDEV" && !be_ignore_line($line[1]))
    {
      $gateway_dev = $line[1];
    }
  }

  close($fh);

  # Select a primary interface.

  # Do any interfaces exist at all?
  if (scalar(keys(%ifaces)) == 0)
  {
    return \%nw;
  }

  # See if only one interface exists.
  elsif (scalar(keys(%ifaces)) == 1)
  {
    $chosen_name = (keys(%ifaces))[0];

#    be_report_info(2, "Only one interface, $chosen_name, exists.  It is being " .
#                      "selected as the primary interface");
  }

  # See if the default gateway device was specified explicitly.
  elsif ($gateway_dev ne "")
  {
    $chosen_name = $gateway_dev;
  }

  # See if the gateway IP can be found on a static interface's network.
  elsif ($g{"gateway"} ne "")
  {
    foreach $key (keys(%ifaces))
    {
      if (!exists($ifaces{$key}->{"address"}) ||
          !exists($ifaces{$key}->{"netmask"})) { next; }

      if (be_ip_calc_network($g{"gateway"}, $ifaces{$key}->{"netmask"}) eq
          be_ip_calc_network($ifaces{$key}->{"address"}, $ifaces{$key}->{"netmask"}))
      {
        $chosen_name = $key;
        last;
      }
    }
  }
  
  # Last ditch.
  
  if ($chosen_name eq "")
  {
    foreach $key (keys(%ifaces))
    {
      if (($key =~ /eth.*/) || ($key =~ /hme.*/) || ($key =~ /ppp.*/))
      {
	$chosen_name = $key;
	last;
      }
    }
  }

  if ($chosen_name eq "")
  {
    $chosen_name = (keys(%ifaces))[0];
  }

  if ($chosen_name ne "")
  {
    $ifaces{$chosen_name}->{"primary"} = 1;
  }

  return \%nw;
}


# SuSE style /etc/rc.config
#
# <filtered lines>
# NETDEV_0="<dev>"
# IPADDR_0="<ip>"
# IFCONFIG_0="<ip> broadcast <broadcast> netmask <netmask>"
# <filtered lines>
#
# BEWARE: This is actually a sourced shell script. We rely on some lenience
# from the user (and the distro) to be able to parse it correctly. The file
# is read by SuSE configuration tools and translated to NET-3 config files
# at strategic times.
#
# Exists: SuSE 6.3
#
# Absent: Red Hat 6.x, Caldera 2.4, TurboLinux 6.0, Mandrake 7.0, SunOS 5.7

# be_network_get_suse_interfaces

sub be_network_get_suse
{
  my (%nw, %ifaces, @iface_name, @iface_ip, @iface_netmask, @iface_method, $fh);

  # Find the file.

  $fh = be_open_read_from_names(@rc_config_names);
  if (not $fh) { return; }  # We didn't find it.

  $nw{"interfaces"} = \%ifaces;

  # Parse the file.

  while (<$fh>)
  {
    @line = split(/[ \n\r\t\"\'=]+/, $_);  # Handles quoted arguments.
    if ($line[0] eq "") { shift(@line); }  # Leading whitespace. He.

    if ($line[0] =~ /NETDEV_([0-9]+)/ && not be_ignore_line($line[1]))
    {
      $iface_name[$1] = $line[1];
    }
    elsif ($line[0] =~ /IPADDR_([0-9]+)/)
    {
      $iface_ip[$1] = $line[1];
    }
    elsif ($line[0] =~ /IFCONFIG_([0-9]+)/)
    {
      my $id = $1;
      shift @line;

      while (@line)
      {
        if (be_ignore_line($line[0])) { last; }

        if ($line[0] eq "broadcast")
        {
          # Calculate this ourselves.

          shift @line;
          shift @line;
        }
        elsif ($line[0] eq "netmask")
        {
	  @iface_netmask[$id] = $line[1];
          shift @line;
          shift @line;
        }
        elsif ($line[0] eq "bootp")
        {
          @iface_method[$id] = "bootp";
          last;
        }
        elsif ($line[0] =~ /dhcp.*/)
        {
          $iface_method[$id] = "dhcp";
          last;
        }
        elsif ($line[0] ne "")
	{
	  $iface_ip[$id] = $line[0];
	  shift @line;
	}
        else { shift @line; }
      }
    }
  }

  close($fh);

  # Hash the information.

  for ($i = 0; @iface_name[$i]; $i++)
  {
    my %iface_hash;
    my $iface = $ifaces{@iface_name[$i]} = \%iface_hash;

    $$iface{"address"} = $iface_ip[$i];
    $$iface{"netmask"} = $iface_netmask[$i];
    if ($iface_ip[$i] ne "" && $iface_method eq "")
    {
      $$iface{"method"} = "static";
    }
    else
    {
      $$iface{"method"} = $iface_method[$i];
    }
  }

  return \%nw;
}


# be_network_get
#
# Gets a hash of all listed interfaces and options, regardless of
# host environment.

sub be_network_get
{
  my $nw;

  $nw = be_network_get_redhat ();

  if (!$nw)
  {
    $nw = be_network_get_debian ();
  }

  if ($nw eq "")
  {
    $nw = be_network_get_suse ();
  }

  return $nw;
}


# --- XML parsing --- #


# Compresses node into a word and returns it.

sub be_xml_get_word
  {
    my $tree = $_[0];
    
    shift @$tree;		# Skip attributes.
    
    while (@$tree)
      {
	if ($$tree[0] == 0)
	  {
	    my $retval;
	    
	    ($retval = $$tree[1]) =~ tr/ \n\r\t\f//d;
	    $retval = be_xml_entities_to_plain(\$retval);
	    return($retval);
	  }
	
	shift @$tree;
	shift @$tree;
      }
    
    return("");
  }

# Compresses node into a size and returns it.

sub be_xml_get_size
  {
    my $tree = $_[0];

    shift @$tree;		# Skip attributes.

    while (@$tree)
      {
        if ($$tree[0] == 0)
          {
            my $retval;

            ($retval = $$tree[1]) =~ tr/ \n\r\t\f//d;
            $retval = be_xml_entities_to_plain(\$retval);
            if ($retval =~ /Mb$/)
              {
                $retval =~ tr/ Mb//d; 
                $retval *= 1024; }
            return($retval);
          }

        shift @$tree;
        shift @$tree;
      }

    return("");
  }

# Replaces misc. whitespace with spaces and returns text.

sub be_xml_get_text
  {
    my $tree = $_[0];
    
    shift @$tree;		# Skip attributes.
    
    while (@$tree)
      {
	if ($$tree[0] == 0)
	  {
	    ($retval = $$tree[1]) =~ tr/\n\r\t\f/    /;
	    $retval = be_xml_entities_to_plain(\$retval);
	    return($retval);
	  }
	
	shift @$tree;
	shift @$tree;
      }
  }


# --- Others --- #

sub be_set_operation
  {
    if ($be_operation ne "")
      {
	print STDERR "Error: You may specify only one major operation.\n\n";
	print STDERR $Usage;
	exit(1);
      }
    
    $be_operation = $_[0];
  }

sub be_begin
{
  $| = 1;
  be_report_begin();
  be_progress_begin();
}

sub be_end
{
  be_progress_end();
  be_report_end();
}


# --- Argument parsing --- #

sub be_init()
{
  my @args = @_;
  
  $be_name = @args[0];
  $be_version = @args[1];
  $be_description = @args[2];
  shift @args; shift @args; shift @args;

  while (@args)
  {
    if    ($args[0] eq "--get"    || $args[0] eq "-g") { be_set_operation("get"); }
    elsif ($args[0] eq "--set"    || $args[0] eq "-s") { be_set_operation("set"); }
    elsif ($args[0] eq "--filter" || $args[0] eq "-f") { be_set_operation("filter"); }
    elsif ($args[0] eq "--help"   || $args[0] eq "-h") { be_print_usage(); exit(0); }
    elsif ($args[0] eq "--version")                    { be_print_version(); exit(0); }
    elsif ($args[0] eq "--prefix" || $args[0] eq "-p")
    {
      if ($be_prefix ne "")
      {
        print STDERR "Error: You may specify --prefix only once.\n\n";
        be_print_usage(); exit(1);
      }

      $be_prefix = $args[1];

      if ($be_prefix eq "")
      {
        print STDERR "Error: You must specify an argument to the --prefix option.\n\n";
        be_print_usage(); exit(1);
      }

      shift @args;  # For the argument.
    }
    elsif ($args[0] eq "--disable-immediate")           { $be_do_immediate = 0; }
    elsif ($args[0] eq "--verbose" || $args[0] eq "-v") { $be_verbose = 1; }
    elsif ($args[0] eq "--progress")                    { $be_progress = 1; }
    elsif ($args[0] eq "--report")                      { $be_reporting = 1; }
    else
    {
      print STDERR "Error: Unrecognized option '$args[0]'.\n\n";
      be_print_usage(); exit(1);
    }

    shift @args;
  }

  if ($be_operation eq "")
  {
    print STDERR "Error: No operation specified.\n\n";
    be_print_usage();
    exit(1);
  }

  be_begin();
}


1;
