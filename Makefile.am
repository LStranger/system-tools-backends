backends = \
disks-conf \
hardware-conf \
memory-conf \
nameresolution-conf \
networking-conf \
shares-conf \
time-conf
##users-conf


scripts_SCRIPTS = $(backends) be.pl

EXTRA_DIST = \
be.pl \
disks-conf.in \
hardware-conf.in \
memory-conf.in \
nameresolution-conf.in \
networking-conf.in \
shares-conf.in \
time-conf.in
##users-conf


$(backends): %-conf: %-conf.in
	sed s#___scriptsdir___#$(scriptsdir)# < $< > $@
	chmod +x $@


