backends = \
hardware-conf \
memory-conf \
nameresolution-conf \
networking-conf \
shares-conf \
time-conf
##users-conf


scripts_SCRIPTS = $(backends) be.pl

EXTRA_DIST = $(scripts_SCRIPTS)

$(backends): %-conf: %-conf.in
	sed s#___scriptsdir___#$(scriptsdir)# < $< > $@
	chmod +x $@


