#!/usr/bin/env perl

require "media.pl";
require "network.pl";
require "parse.pl";
require "debug.pl";
require "filesys.pl";
require "share.pl";
require "print.pl";


@platforms = ( "redhat-6.2", "redhat-7.0", "debian-2.2" );


&xst_init ("test", "0.0.0", "Test script.", @ARGV);
&xst_platform_ensure_supported (@platforms);


sub test_open
{
  $fh = be_open_read_from_names ("/tmp/pekk");
  if (not $fh) { return; }

  while (<$fh>)
  {
    print $_;
  }

  print "I think I found it.\n";
}


sub test_media
{
  @devices = &xst_media_get_list();
  print "\n";

  for $dev (@devices)
  {
    print "/dev/" , $dev->{"device"} . "\n" .
          "  Type:         " . $dev->{"type"} . "\n" .
          "  Media:        " . $dev->{"media"} . "\n" .
          "  Model:        " . $dev->{"model"} . "\n" .
          "  Driver:       " . $dev->{"driver"} . "\n" .
          "  Removable:    " . &be_print_boolean_yesno ($dev->{"is_removable"}) . "\n" .
          "  Mounted:      " . &be_print_boolean_yesno ($dev->{"is_mounted"}) . "\n";

    if ($dev->{"point_listed"} || $dev->{"point_actual"})
    {
      print "  Mount point:  ";

      if ($dev->{"point_listed"})
      {
        print $dev->{"point_listed"} . " (listed) ";
      }

      if ($dev->{"point_actual"})
      {
        print $dev->{"point_actual"} . " (actual)";
      }

      print "\n";
    }

    if ($dev->{"fs_listed"} || $dev->{"fs_actual"})
    {
      print "  File system:  ";

      if ($dev->{"fs_listed"})
      {
        print $dev->{"fs_listed"} . " (listed) ";
      }

      if ($dev->{"fs_actual"})
      {
        print $dev->{"fs_actual"} . " (actual)";
      }

      print "\n";
    }

    print "\n";
  }
}


sub test_interfaces
{
  my $ifaces;
  
  $ifaces = &xst_network_conf_get();
  &xst_debug_print_struct ($ifaces);
}


# ---

$hash = &xst_print_conf_get ();
&xst_debug_print_struct ($hash);

# &xst_replace_remove_cap_section ("/etc/printcap", "lp");
&xst_replace_cap ("/etc/printcap", "lpk", "lp", "/dev/pekk");

# @arr = &xst_parse_cap_sections ("/etc/termcap");

# for $i (@arr)
# {
#   my $tc = &xst_parse_cap      ("/etc/termcap", $i, "tc");
#   my $am = &xst_parse_cap_bool ("/etc/termcap", $i, "am");
#    print "$i\t\t($tc)";
# 	print " (am)" if ($am == 1);
#	print "\n";
# }

# $arr = &xst_filesys_parse_fstab ("/etc/fstab");
# $arr = &xst_filesys_parse_mtab ("/etc/mtab");

# print @arr[0] . "\n";

# &xst_filesys_table_remove ($arr, &xst_filesys_table_find ($arr, "point", "/"));
# &xst_filesys_table_remove ($arr, &xst_filesys_table_find ($arr, "point", "/mnt/floppy"));
# &xst_debug_print_struct ($arr);

# $table = &xst_share_parse_smb_conf ("/etc/samba/smb.conf");
# &xst_share_replace_smb_conf ("/etc/samba/smb.conf.test", $table);

# &test_interfaces();
# &test_media();

# be_service_enable(90, "-d pekk", "samba", "smbd", "smb", "httpd");
# be_service_disable(15, "-d pekk", "samba", "smbd", "smb", "httpd");

# be_run("ls /etc");
# be_run("ls /etc");
# be_run("ls /etc");
# be_run("ls /etc");
# be_run("grokk pekk fette");
# be_run("grokk pekk fette");
# be_run("grokk pekk fette");

# be_locate_tool("pekk");
# be_locate_tool("pekk");

