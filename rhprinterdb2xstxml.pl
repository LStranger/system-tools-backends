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

    print $_ . "\n";
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
      &print_xml_line ("<printerdef id='$1'>");
      &xml_enter;
    }
    elsif (/^EndEntry/)
    {
      &xml_leave;
      &print_xml_line ("</printerdef>\n");
    }
    elsif (/^GSDriver: *(.*)/)
    {
      &print_xml_line ("<gsdriver name='$1'/>");
    }
    elsif (/^Description: *{ *(.*) *}/)
    {
      &print_xml_line ("<description>$1</description>");
    }
    elsif (/^About:/)
    {
      &convert_about ();
    }
    elsif (/^Resolu?tion: *\{ *([a-zA-Z0-9]+) *\} *\{ *([a-zA-Z0-9]+) *\}/)
    {
      &print_xml_line ("<resolution x='$1' y='$2'/>");
    }
    elsif (/^BitsPerPixel: *\{ *([^\} ]+) *\} *\{ *([^\}]+)\}/)
    {
      &print_xml_line ("<mode id='$1'>$2</mode>");
    }
    else
    {
      print "\t*** " . $_ . "\n";
    }
  }
}

&convert ();
