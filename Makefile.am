SUBDIRS =

backends = \
	disks-conf \
	memory-conf \
	network-conf \
	shares-conf \
	time-conf \
	users-conf \
	boot-conf \
	print-conf \
	internetsharing-conf \
	mouse-conf \
	package-conf \
	display-conf

PERLBODY = \
	gettext.pl.in \
	parse.pl.in \
	replace.pl.in \
	file.pl.in \
	general.pl.in \
	platform.pl.in \
	report.pl.in \
	xml.pl.in \
	service.pl.in \
	util.pl.in \
	network.pl.in \
	boot.pl.in \
	filesys.pl.in \
	media.pl.in \
	debug.pl.in \
	print.pl.in \
	share.pl.in \
	x.pl.in \
	font.pl.in


perl_libs = \
	$(PERLBODY:.pl.in=.pl)

scripts_SCRIPTS = $(backends) $(perl_libs) guess_system.sh

EXTRA_DIST = \
	$(PERLBODY) \
	disks-conf.in \
	memory-conf.in \
	network-conf.in \
	shares-conf.in \
	time-conf.in \
	users-conf.in \
	boot-conf.in \
	print-conf.in \
	mouse-conf.in \
	internetsharing-conf.in \
	package-conf.in \
	display-conf.in \
	guess_system.sh \
	\
	README \
	AUTHORS \
	NEWS

CLEANFILES = $(backends) $(perl_libs)

$(backends): %-conf: %-conf.in
	sed s#___scriptsdir___#$(scriptsdir)#\;s#___version___#$(VERSION)# < $< > $@
	chmod +x $@

$(perl_libs): %.pl: %.pl.in
	sed -e s#___scriptsdir___#$(scriptsdir)# -e s#___bindir___#$(bindir)# < $< > $@

