#!/usr/bin/env perl
#-*-perl-*-

# Common stuff for the helix-setup-tools backends.
#
# Copyright (C) 2000 Helix Code, Inc.
#
# Author: Hr. Hans Petter Jansson <hpj@helixcode.com>
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


@hosts_names =             ( "/etc/hosts" );


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


#@be_xml_scan_list;


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
    
    #  $" = "\n";
    #  print "@list\n";
  }


@be_xml_entities = ( "&lt;", '<', "&gt;", '>', "&apos;", '\'', "&quot;", '"' );

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
    if (($_[0] =~ /^\#/) || ($_[0] =~ /^[ \t\n\r]*$/)) { return(1); }
    return(0);
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
    if ( $value eq $item ) { return 1; }
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


# --- File operations --- #

@be_builtin_paths = ( "/sbin", "/usr/sbin", "/usr/local/sbin", "/bin",
                      "/usr/bin", "/usr/local/bin" );

sub be_locate_tool
{
  my $found = "";
  my @user_paths;

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

  if (!$found)
  {
    be_report_warning(96, "Couldn't find $_[0] tool in any of " .
      join (", ", @be_builtin_paths) . " : " . join (", ", @user_paths));
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

  if ($fname ne "") 
  { 
    be_report_info(99, "Reading options from \"$fullname\"");
  }
  else 
  { 
    be_report_warning(99, "Could not read \[@_\]");
  }
    
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
	    be_report_warning(97, "Could not find \[@_\]. Writing to \"$fullname\"");
	  }
      }
    else
      {
	(my $fullname = "$be_prefix/$name") =~ tr/\//\//s;
	be_report_info(98, "Found \"$name\". Writing to \"$fullname\"");
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
	be_report_error(99, "Failed to write to \"$name\"");
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
	    be_report_warning(97, "Could not find \[@_\]. Patching \"$fullname\"");
	  }
      }
    else
      {
	(my $fullname = "$be_prefix/$name") =~ tr/\//\//s;
	be_report_info(98, "Found \"$name\". Patching \"$fullname\"");
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
	be_report_error(99, "Failed to write to \"$name\"");
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


# --- Configuration utilities --- #


# be_ensure_local_host_entry (<ip>, <hostname>)
#
# Given a text IP and hostname, add the hostname as an alias for the local
# hosts (provided) IP to the /etc/hosts database. This is required for tools
# like nmblookup to work on a computer with no reverse name or DNS.

sub be_ensure_local_host_entry
{
  my $local_ip = @_[0];
  my $local_hostname = @_[1];
  local *INFILE;
  local *OUTFILE;
  my $written = 0;

  if ($local_ip eq "" || $local_hostname eq "") { return; }

  # Find the file.
  
  (*INFILE, *OUTFILE) = be_open_filter_write_from_names(@hosts_names);
  if (not *OUTFILE) { return; }  # We didn't find it.

  # Write the file, preserving as much as possible from INFILE.

  while (<INFILE>)
  {
    @line = split(/[ \n\r\t]+/, $_);
    if ($line[0] eq "") { shift(@line); }  # Leading whitespace. He.

    if ($line[0] ne "" && (not be_ignore_line($line[0])) &&
#       ($line[0] =~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/) &&
        $line[0] eq $local_ip)
    {
      # Found $local_ip. Add $local_hostname to its list, if it's not already there.

      shift @line;

      be_push_unique(\@line, $local_hostname);

      printf OUTFILE ("%-16s", $local_ip);
      for $alias (@line) { print OUTFILE " $alias"; }
      print OUTFILE "\n";

      $written = 1;
    }
    else { print OUTFILE; }
  }

  # If the IP wasn't present, add the entry at the end.

  if (!$written) { printf OUTFILE ("%-16s %s\n", $local_ip, $local_hostname); }
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
