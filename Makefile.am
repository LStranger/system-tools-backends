backends = \
disks-conf \
memory-conf \
nameresolution-conf \
network-conf \
shares-conf \
time-conf \
users-conf \
boot-conf

perl_libs = \
be.pl \
network.pl \
media.pl \
parse.pl \
replace.pl

scripts_SCRIPTS = $(backends) $(perl_libs) guess_system.sh

EXTRA_DIST = \
be.pl.in \
network.pl.in \
parse.pl.in \
replace.pl.in \
disks-conf.in \
memory-conf.in \
nameresolution-conf.in \
network-conf.in \
shares-conf.in \
time-conf.in \
users-conf.in \
boot-conf.in

CLEANFILES = $(backends) $(perl_libs)

$(backends): %-conf: %-conf.in
	sed s#___scriptsdir___#$(scriptsdir)# < $< > $@
	chmod +x $@

$(perl_libs): %.pl: %.pl.in
	sed s#___scriptsdir___#$(scriptsdir)# < $< > $@
	chmod +x $@

