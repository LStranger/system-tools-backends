#!/usr/bin/env perl

require "media.pl";
require "network.pl";
require "parse.pl";
require "debug.pl";
require "filesys.pl";
require "share.pl";
require "print.pl";


@platforms = ( "redhat-6.2", "redhat-7.0", "redhat-7.1", "debian-2.2" );

sub set
{
}

sub get
{
}

sub filter
{
}

$directives =
{
  "get"    => [ \&get,    [], "" ],
	"set"    => [ \&set,    [], "" ],
	"filter" => [ \&filter, [], "" ]
};


$tool = &gst_init ("test", "0.0.0", "Test script.", $directives, @ARGV);
&gst_platform_ensure_supported ($tool, @platforms);


# $tree = &gst_xml_scan ("/etc/alchemist/namespace/printconf/local.adl");
# &gst_debug_print_struct ($tree);

print "He.\n";

#($model, $compressed) = &gst_xml_model_scan ("/etc/alchemist/namespace/printconf/local.adl");
#print &gst_xml_model_print ($model);

&gst_replace_xml_attribute_with_type ("/etc/alchemist/namespace/printconf/local.adl",
                                      "/adm_context/datatree/printconf/print_queues/new/fitte/",
																			"VALUE", "STRING", "p0ke");

# $branch = &gst_xml_model_find ($model, "/adm_context/datatree/");
# &gst_xml_model_set_pcdata ($branch, "FAAN");
# &gst_xml_model_set_attribute ($branch, "Jern", "Jepp");

# print &gst_parse_xml ("/etc/alchemist/namespace/printconf/local.adl",
#                       "/adm_context/datatree/printconf/print_queues/lpekk/filter_type", "VALUE") . "\n";

