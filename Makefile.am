SUBDIRS = files

BACKENDSBODY = \
	dhcpd-conf.in \
	disks-conf.in \
	memory-conf.in \
	network-conf.in \
	runlevel-conf.in \
	shares-conf.in \
	time-conf.in \
	users-conf.in \
	boot-conf.in \
	print-conf.in \
	mouse-conf.in \
	internetsharing-conf.in \
	package-conf.in \
	display-conf.in \
	font-conf.in

PERLBODY = \
	boot.pl.in      \
	boot-grub.pl.in \
	boot-lilo.pl.in \
	dhcpd.pl.in     \
	debug.pl.in     \
	file.pl.in      \
	filesys.pl.in   \
	font.pl.in      \
	general.pl.in   \
	gettext.pl.in   \
	ishare.pl.in    \
	media.pl.in     \
	network.pl.in   \
	parse.pl.in     \
	partition.pl.in \
	platform.pl.in  \
	print.pl.in     \
	replace.pl.in   \
	report.pl.in    \
	service.pl.in   \
	service-list.pl.in	\
	share.pl.in     \
	tokenizer.pl.in \
	util.pl.in      \
	x.pl.in         \
	xml.pl.in

perl_libs = $(PERLBODY:.pl.in=.pl)

backends = $(BACKENDSBODY:.in=)

scripts_SCRIPTS = $(backends) $(perl_libs) guess_system.sh type1inst

EXTRA_DIST = \
	$(PERLBODY) \
	$(BACKENDSBODY) \
	guess_system.sh \
	type1inst		 \
	README \
	AUTHORS \
	NEWS

CLEANFILES = $(backends) $(perl_libs)

$(backends): %-conf: %-conf.in
	sed 's#___scriptsdir___#$(scriptsdir)#;s#___version___#$(VERSION)#;s#___filesdir___#$(filesdir)#;s#___bindir___#$(bindir)#' < $< > $@
	chmod +x $@

$(perl_libs): %.pl: %.pl.in
	sed 's#___scriptsdir___#$(scriptsdir)#;s#___version___#$(VERSION)#;s#___filesdir___#$(filesdir)#;s#___bindir___#$(bindir)#' < $< > $@


