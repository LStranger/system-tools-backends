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
parse.pl \
replace.pl \
file.pl \
general.pl \
platform.pl \
report.pl \
xml.pl \
service.pl \
util.pl \
network.pl \
boot.pl \
debug.pl

scripts_SCRIPTS = $(backends) $(perl_libs) guess_system.sh

EXTRA_DIST = \
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
debug.pl.in \
disks-conf.in \
memory-conf.in \
nameresolution-conf.in \
network-conf.in \
shares-conf.in \
time-conf.in \
users-conf.in \
boot-conf.in \
guess_system.sh

CLEANFILES = $(backends) $(perl_libs)

$(backends): %-conf: %-conf.in
	sed s#___scriptsdir___#$(scriptsdir)# < $< > $@
	chmod +x $@

$(perl_libs): %.pl: %.pl.in
	sed s#___scriptsdir___#$(scriptsdir)# < $< > $@

