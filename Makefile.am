backends = \
disks-conf \
memory-conf \
nameresolution-conf \
network-conf \
shares-conf \
time-conf \
users-conf

scripts_SCRIPTS = $(backends) be.pl guess_system.sh

EXTRA_DIST = \
be.pl \
disks-conf.in \
memory-conf.in \
nameresolution-conf.in \
network-conf.in \
shares-conf.in \
time-conf.in \
users-conf.in

CLEANFILES = $(backends)

$(backends): %-conf: %-conf.in
	sed s#___scriptsdir___#$(scriptsdir)# < $< > $@
	chmod +x $@
