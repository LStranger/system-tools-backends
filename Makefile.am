SUBDIRS = files

backends = \
	boot-conf            \
	disks-conf           \
	display-conf         \
	internetsharing-conf \
	memory-conf          \
	mouse-conf           \
	network-conf         \
	package-conf         \
	print-conf           \
	runlevel-conf        \
	shares-conf          \
	time-conf            \
	users-conf

PERLBODY = \
	boot.pl.in     \
	debug.pl.in    \
	file.pl.in     \
	filesys.pl.in  \
	font.pl.in     \
	general.pl.in  \
	gettext.pl.in  \
	ishare.pl.in   \
	media.pl.in    \
	network.pl.in  \
	parse.pl.in    \
	platform.pl.in \
	print.pl.in    \
	replace.pl.in  \
	report.pl.in   \
	service.pl.in  \
	share.pl.in    \
	util.pl.in     \
	x.pl.in        \
	xml.pl.in


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

