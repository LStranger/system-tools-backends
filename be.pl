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

# --- Operation modifying variables --- #

# Variables are set to their default value, which may be overridden by user. Note
# that a $prefix of "" will cause the configurator to use '/' as the base path,
# and disables creation of directories and writing of previously non-existent
# files.

$be_prefix = "";
$be_verbose = 0;
$be_do_immediate = 1;

# for debugging (perl -d) purposes. set to "" for normal operation:
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
	
    if (($el eq "") || $el =~ /^\<[!?].*\>$/s) { next; } # Empty strings, PI and DTD must go.
    if ($el =~ /^\<.*\/\>$/s) # Empty.
    {
	    $el =~ /^\<([a-zA-Z_-]+).*\/\>$/s;
	 	  push(@list, $1);
			push(@list, be_xml_scan_make_kid_array($el));
	  }
	  elsif ($el =~ /^\<\/.*\>$/s) # End.
	  {
	    last;
	  }
	  elsif ($el =~ /^\<.*\>$/s) # Start.
	  {
	    $el =~ /^\<([a-zA-Z_-]+).*\>$/s;
		  push(@list, $1);
		  $sublist = be_xml_scan_make_kid_array($el);
		  push(@list, be_xml_scan_recurse($sublist));
		  next;
	  }
	  elsif ($el ne "")	# PCDATA.
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
		
    print STDERR $doc if $be_verbose;
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


# --- String and array manipulation --- #

# Boolean/strings conversion.

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


# Pushes a value to an array, only if it's not already in there.
# I'm sure there's a smarter way to do this. Should only be used for small lists,
# as it's O(N^2). Larger lists with unique members should use a hash.

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


sub be_is_line_comment_start
  {
    if (($_[0] =~ /^\#/) || ($_[0] =~ /^[ \t\n\r]*$/)) { return(1); }
    return(0);
  }


# --- File operations --- #

@be_builtin_paths = ( "/sbin", "/usr/sbin", "/usr/local/sbin", "/bin", "/usr/bin",
                   "/usr/local/bin" );

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

  if (! $found && $be_verbose) {
	  print STDERR "Couldn't find $_[0] program in path %s:%s", 
		  join (",", @be_builtin_paths), join (",", @user_paths);
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
	be_report_info(98, "Found \"$name\". Writing to \"$fullname\".\n");
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
    
    if (!open(FILE, ">$name") && $be_verbose)
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
    
    if (!open(OUTFILE, ">$name") && $be_verbose)
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

$be_operation = "";  # Major operation user wants to perform. [get | set | filter]


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

  while (@args)
  {
    if    ($args[0] eq "--get"    || $args[0] eq "-g") { be_set_operation("get"); }
    elsif ($args[0] eq "--set"    || $args[0] eq "-s") { be_set_operation("set"); }
    elsif ($args[0] eq "--filter" || $args[0] eq "-f") { be_set_operation("filter"); }
    elsif ($args[0] eq "--help"   || $args[0] eq "-h") { print $Usage; exit(0); }
    elsif ($args[0] eq "--version")                    { print "$version\n"; exit(0); }
    elsif ($args[0] eq "--prefix" || $args[0] eq "-p")
    {
      if ($be_prefix ne "")
      {
        print STDERR "Error: You may specify --prefix only once.\n\n";
        print STDERR $Usage; exit(1);
      }

      $be_prefix = $args[1];

      if ($be_prefix eq "")
      {
        print STDERR "Error: You must specify an argument to the --prefix option.\n\n";
        print STDERR $Usage; exit(1);
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
      print STDERR $Usage; exit(1);
    }

    shift @args;
  }

  be_begin();
}


1;
