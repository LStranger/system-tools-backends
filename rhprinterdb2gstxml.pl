#!/usr/bin/env perl

$indent_level = 0;

sub print_xml_line
{
  my ($text) = @_;

  print " " x $indent_level;
  print $text . "\n";
}

sub xml_enter
{
  $indent_level += 2;
}

sub xml_leave
{
  $indent_level -= 2;
}

sub xml_quote
{
  my $in = $_[0];
  my $out = "";
  my @xe;
  my $joined = 0;
  my @xml_entities = ( "&lt;", '<', "&gt;", '>', "&apos;", '\'', "&quot;", '"', "&amp;", '&' );

  my @clist = split (//, $in);
  
  while (@clist)
  {
    # Find character and join its entity equivalent.
    # If none found, simply join the character.
	
    $joined = 0;		# Cumbersome.
    
    for (@xe = @xml_entities; @xe && !$joined; )
    {
      if ($xe [1] eq $clist [0]) { $out = join ('', $out, $xe [0]); $joined = 1; }
      shift @xe; shift @xe;
    }
	
    if (!$joined) { $out = join ('', $out, $clist [0]); }
    shift @clist;
  }
  
  return $out;
}

sub convert_about
{
  &print_xml_line ("<comment>");

  while (<STDIN>)
  {
    chomp;
    s/^[ \t]+//;
    s/[ \\]+$//;
    if (/^\#/) { next; }
    if (/^\}/) { last; }
    s/\\n\\n/\n/g;
    s/\\n/\n/g;

    print &xml_quote ($_) . "\n";
  }

  &print_xml_line ("</comment>");
}

sub convert
{
  while (<STDIN>)
  {
    chomp;
    s/^[ \t]+//;
    s/[ \\]+$//;
    if (/^\#/ || /^$/) { next; }

    if (/^StartEntry: *(.*)/)
    {
      &print_xml_line ("<printerdef id='" . &xml_quote ($1) . "'>");
      &xml_enter;
    }
    elsif (/^EndEntry/)
    {
      &xml_leave;
      &print_xml_line ("</printerdef>\n");
    }
    elsif (/^GSDriver: *(.*)/)
    {
      &print_xml_line ("<gsdriver name='" . &xml_quote ($1) . "'/>");
    }
    elsif (/^Description: *{ *(.*) *}/)
    {
      &print_xml_line ("<description>" . &xml_quote ($1) . "</description>");
    }
    elsif (/^About:/)
    {
      &convert_about ();
    }
    elsif (/^Resolu?tion: *\{ *([a-zA-Z0-9]+) *\} *\{ *([a-zA-Z0-9]+) *\}/)
    {
      &print_xml_line ("<resolution x='" . &xml_quote ($1) . "' y='" . &xml_quote ($2) . "'/>");
    }
    elsif (/^BitsPerPixel: *\{ *([^\} ]+) *\} *\{ *([^\}]+)\}/)
    {
      &print_xml_line ("<mode id='" . &xml_quote ($1) . "'>" . &xml_quote ($2) . "</mode>");
    }
    else
    {
      print "\t*** " . $_ . "\n";
    }
  }
}

&convert ();
