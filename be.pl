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
$be_progress = 0;
$be_do_immediate = 1;


# --- Progress printing --- #


sub be_print_progress
{
  if ($be_progress) { print "."; }
}

# --- XML print formatting  --- #

# be_enter: Call after entering a block. Increases indent level.
# be_leave: Call before leaving a block. Decreases indent level.
# be_indent: Call before printing a line. Indents to current level. 
# be_vspace: Ensures there is a vertical space of one and only one line.

$be_indent_level = 0;
$be_have_vspace = 0;

sub be_xml_enter  { $be_indent_level += 2; }
sub be_xml_leave  { $be_indent_level -= 2; }
sub be_xml_indent { for ($i = 0; $i < $be_indent_level; $i++) { print " "; } $be_have_vspace = 0; }
sub be_xml_vspace { if (not $be_have_vspace) { print "\n"; $be_have_vspace = 1; } }


# --- XML scanning --- #

# This code tries to replace XML::Parser scanning from stdin in tree mode.


@be_xml_scan_list;


sub be_xml_scan_make_kid_array
  {
    my %hash = {};
    my @sublist;
    
    @attr = @_[0] =~ /[^\t\n\r ]+[\t\n\r ]*([a-zA-Z]+)[ \t\n\r]*\=[ \t\n\r\"\']*([a-zA-Z]+)/g;
    %hash = @attr;
    
    push(@sublist, \%hash);
    return(\@sublist);
  }


sub be_xml_scan_recurse;

sub be_xml_scan_recurse
  {
    my @list;
    if (@_) { @list = @_[0]->[0]; }
    
    while (@be_xml_scan_list)
      {
	$el = @be_xml_scan_list[0]; shift @be_xml_scan_list;
	
	if ((not $el) || $el =~ /^\<[!?].*\>$/s) { next; } # Empty strings, PI and DTD must go.
	
	if ($el =~ /^\<.*\/\>$/s) # Empty.
	  {
	    $el =~ /^\<([a-zA-Z]+).*\/\>$/s;
	    push(@list, $1);
	    push(@list, be_xml_scan_make_kid_array($el));
	  }
	elsif ($el =~ /^\<\/.*\>$/s) # End.
	  {
	    last;
	  }
	elsif ($el =~ /^\<.*\>$/s) # Start.
	  {
	    $el =~ /^\<([a-zA-Z]+).*\>$/s;
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
    $doc .= $i while ($i = <STDIN>);
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
    my $in = @_[0];
    my $out = "";
    my @xe;
    
    $in = $$in;
    
    my @elist = ($in =~ /([^&]*)(\&[a-zA-Z]+\;)?/mg); # text, entity, text, entity, ...
    
    while (@elist)
      {
	# Join text.
	
	$out = join('', $out, @elist[0]);
	shift @elist;
	
	# Find entity and join its text equivalent.
	# Unknown entities are simply removed.
	
	for (@xe = @be_xml_entities; @xe; )
	  {
	    if (@xe[0] eq @elist[0]) { $out = join('', $out, @xe[1]); last; }
	    shift @xe; shift @xe;
	  }
	
	shift @elist;
      }
    
    return($out);
  }


sub be_xml_plain_to_entities
  {
    my $in = @_[0];
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
	    if (@xe[1] eq @clist[0]) { $out = join('', $out, @xe[0]); $joined = 1; }
	    shift @xe; shift @xe;
	  }
	
	if (!$joined) { $out = join('', $out, @clist[0]); }
	shift @clist;
      }
    
    return($out);
  }


# --- String and array manipulation --- #

# Boolean/strings conversion.

sub be_read_boolean
  {
    if (@_[0] eq "true") { return(1); }
    elsif (@_[0] eq "yes") { return(1); }
    return(0);
  }

sub be_print_boolean_yesno
  {
    if (@_[0] == 1) { return("yes"); }
    return("no");
  }

sub be_print_boolean_truefalse
  {
    if (@_[0] == 1) { return("true"); }
    return("false");
  }


# Pushes a value to an array, only if it's not already in there.
# I'm sure there's a smarter way to do this. Should only be used for small lists,
# as it's O(N^2). Larger lists with unique members should use a hash.

sub be_push_unique
  {
    my $arr = @_[0];
    my $found;
    my $i;
    
    # Go through all elements in pushed list.
    
    for ($i = 1; @_[$i]; $i++)
      {
	# Compare against all elements in destination array.
	
	$found = "";
	for $elem (@$arr)
	  {
	    if ($elem eq @_[$i]) { $found = $elem; last; }
	  }
	
	if ($found eq "") { push(@$arr, @_[$i]); }
      }
  }


sub be_is_line_comment_start
  {
    if (@_[0] =~ /^\#/) { return(1); }
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
    if (-x "$path/@_[0]") { $found = "$path/@_[0]"; last; }
  }

  # Try builtin paths.

  for $path (@be_builtin_paths)
  {
    if (-x "$path/@_[0]") { $found = "$path/@_[0]"; last; }
  }
  
  return($found);
}

sub be_open_read_from_names
  {
    local *FILE;
    my $fname = "";
    
    for $name (@_)
      {
	if (open(FILE, "$be_prefix/$name")) { $fname = $name; last; }
      }
    
    if ($be_verbose)
      {
	(my $fullname = "$be_prefix/$fname") =~ tr/\//\//s;  # '//' -> '/'	

	if ($fname ne "") 
	  { 
	    print STDERR "Reading options from \"$fullname\".\n"; 
	  }
	else 
	  { 
	    print STDERR "Could not read \[@_\].\n"; 
	  }
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
	    if ($be_verbose) { print STDERR "No file to replace: \[@_\].\n"; }
	    return(0);
	  }
	else
	  {
	    $name = @_[0];
	    if ($be_verbose)
	      {
		(my $fullname = "$prefix/$name") =~ tr/\//\//s;
		print STDERR "Could not find \[@_\]. Writing to \"$fullname\".\n";
	      }
	  }
      }
    elsif ($be_verbose)
      {
	(my $fullname = "$prefix/$name") =~ tr/\//\//s;
	print STDERR "Found \"$name\". Writing to \"$fullname\".\n";
      }
    
    ($name = "$prefix/$name") =~ tr/\//\//s;  # '//' -> '/' 
      create_path($name);
    
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
	print STDERR "Error: Failed to write to \"$name\". Are you root?\n";
      }
    
    return *FILE;
  }


sub be_open_filter_write_from_names
  {
    local *INFILE;
    local *OUTFILE;
    my $name;
    
    # Find out where it lives.
    
    for $elem (@_) { if (stat($elem) ne "") { $name = $elem; last; } }
    
    if ($name eq "")
      {
	# If we couldn't locate the file, and have no prefix, give up.
	
	# If we have a prefix, but couldn't locate the file relative to '/',
	# take the first name in the array and let that be created in $prefix.
	
	if ($prefix eq "")
	  {
	    if ($be_verbose) { print STDERR "No file to patch: \[@_\].\n"; }
	    return(0, 0);
	  }
	else
	  {
	    $name = @_[0];
	    if ($be_verbose)
	      {
		(my $fullname = "$prefix/$name") =~ tr/\//\//s;
		print STDERR "Could not find \[@_\]. Patching \"$fullname\".\n";
	      }
	  }
      }
    elsif ($be_verbose)
      {
	(my $fullname = "$prefix/$name") =~ tr/\//\//s;
	print STDERR "Found \"$name\". Patching \"$fullname\".\n";
      }
    
    ($name = "$prefix/$name") =~ tr/\//\//s;  # '//' -> '/' 
      create_path($name);
    
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
	print STDERR "Error: Failed to write to \"$name\". Are you root?\n";
      }
    
    return(*INFILE, *OUTFILE);
  }


sub be_create_path
  {
    my $path;
    
    $path = @_[0];
    my @pelem = split(/\//, $path); # 'a/b/c/d/' -> 'a', 'b', 'c', 'd', ''
    
    for ($path = ""; @pelem; shift @pelem)
      {
	if (@pelem[1] ne "")
	  {
	    $path = "$path@pelem[0]";
	    mkdir($path, 0770);
	    $path = "$path/";
	  }
      }
  }


# --- XML parsing --- #


# Scan XML from standard input to an internal tree.

sub be_xml_parse
  {
    # Scan XML to tree.
    
    $tree = be_xml_scan;
    
    # Walk the tree recursively and extract configuration parameters.
    # This is the top level - find and enter the "memory" tag.
    
    while (@$tree)
      {
	if (@$tree[0] eq "memory") { be_xml_parse_memory(@$tree[1]); }
	
	shift @$tree;
	shift @$tree;
      }
    
    return($tree);
  }

# Compresses node into a word and returns it.

sub be_xml_get_word
  {
    my $tree = @_[0];
    
    shift @$tree;		# Skip attributes.
    
    while (@$tree)
      {
	if (@$tree[0] == 0)
	  {
	    my $retval;
	    
	    ($retval = @$tree[1]) =~ tr/ \n\r\t\f//d;
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
    my $tree = @_[0];

    shift @$tree;		# Skip attributes.

    while (@$tree)
      {
        if (@$tree[0] == 0)
          {
            my $retval;

            ($retval = @$tree[1]) =~ tr/ \n\r\t\f//d;
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
    my $tree = @_[0];
    
    shift @$tree;		# Skip attributes.
    
    while (@$tree)
      {
	if (@$tree[0] = 0)
	  {
	    ($retval = @$tree[1]) =~ tr/\n\r\t\f/    /;
	    $retval = be_xml_entities_to_plain(\$retval);
	    return($retval);
	  }
	
	shift @$tree;
	shift @$tree;
      }
  }


# --- Others ---

$be_operation = "";		# Major operation user wants to perform. [get | set | filter]


sub be_set_operation
  {
    if ($be_operation ne "")
      {
	print STDERR "Error: You may specify only one major operation.\n\n";
	print STDERR $Usage;
	exit(1);
      }
    
    $be_operation = @_[0];
  }

1;

