# $URL$
# $Id$

#######################################################################
# Default compilation parameters. Normally don't edit these           #
#######################################################################

srcdir      ?= .

DEFINES     := -DUNIX
STANDALONE  := 
# This one will go away once all tools are converted
NO_MAIN     := -DEXPORT_MAIN
LDFLAGS     := $(LDFLAGS)
INCLUDES    := -I. -I$(srcdir)
LIBS        :=
OBJS        :=
DEPDIR      := .deps

# Load the make rules generated by configure
# HACK: We don't yet support configure in the tools SVN module, but at least one can
# manually create a config.mk files with overrides, if needed.
-include config.mk

CXXFLAGS  += -g

# Additional warnings
CXXFLAGS:= -Wall $(CXXFLAGS)
# Turn off some annoying and not-so-useful warnings
CXXFLAGS+= -Wno-long-long -Wno-multichar -Wno-unknown-pragmas -Wno-reorder
# Enable even more warnings...
#CXXFLAGS+= -pedantic	# -pedantic is too pedantic, at least on Mac OS X
CXXFLAGS+= -Wpointer-arith -Wcast-align
CXXFLAGS+= -Wshadow -Wimplicit -Wundef -Wnon-virtual-dtor -Wwrite-strings

# Enable checking of pointers returned by "new"
CXXFLAGS+= -fcheck-new

# There is a nice extra warning that flags variables that are potentially
# used before being initialized. Very handy to catch a certain kind of
# bugs. Unfortunately, it only works when optimizations are turned on,
# which is why we normally don't use it.
#CXXFLAGS+= -O -Wuninitialized

#######################################################################
# Default commands - put the necessary replacements in config.mk      #
#######################################################################

CAT     ?= cat
CP      ?= cp
ECHO    ?= printf
INSTALL ?= install
MKDIR   ?= mkdir -p
RM      ?= rm -f
RM_REC  ?= $(RM) -r
ZIP     ?= zip -q

CC      := gcc
CXX     := g++

#######################################################################

# HACK: Until we get proper module support, add these "module dirs" to 
# get the dependency tracking code working.
MODULE_DIRS := ./ utils/ common/ gui/

#######################################################################

TARGETS := \
	decine$(EXEEXT) \
	dekyra$(EXEEXT) \
	descumm$(EXEEXT) \
	desword2$(EXEEXT) \
	degob$(EXEEXT) \
	tools_cli$(EXEEXT) \
	tools_gui$(EXEEXT)

UTILS := \
	common/file.o \
	common/md5.o \
	common/util.o \
	utils/adpcm.o \
	utils/audiostream.o \
	utils/voc.o \
	utils/wave.o

all: $(TARGETS)

install: $(TARGETS)
	for i in $^ ; do install -p -m 0755 $$i $(DESTDIR) ; done

bundle_name = ScummVM\ Tools.app
bundle: $(TARGETS)
	mkdir -p $(bundle_name)
	mkdir -p $(bundle_name)/Contents
	mkdir -p $(bundle_name)/Contents/MacOS
	mkdir -p $(bundle_name)/Contents/Resources
	echo "APPL????" > $(bundle_name)/Contents/PkgInfo
	cp $(srcdir)/dist/macosx/Info.plist $(bundle_name)/Contents/
	cp $(srcdir)/gui/media/*.* $(bundle_name)/Contents/Resources
	cp tools_gui$(EXEEXT) $(bundle_name)/Contents/MacOS/

decine$(EXEEXT): decine.o
	$(CXX) $(LDFLAGS) -o $@ $+

dekyra$(EXEEXT): dekyra.o dekyra_v1.o $(UTILS)
	$(CXX) $(LDFLAGS) -o $@ $+

descumm$(EXEEXT): descumm-tool.o descumm.o descumm6.o descumm-common.o tool.o $(UTILS)
	$(CXX) $(LDFLAGS) -o $@ $+

desword2$(EXEEXT): desword2.o tool.o $(UTILS)
	$(CXX) $(LDFLAGS) -o $@ $+

degob$(EXEEXT): degob.o degob_script.o degob_script_v1.o degob_script_v2.o degob_script_v3.o \
	degob_script_v4.o degob_script_v5.o degob_script_v6.o degob_script_bargon.o \
	tool.o $(UTILS)
	$(CXX) $(LDFLAGS) -o $@ $+

create_sjisfnt$(EXEEXT): create_sjisfnt.o $(UTILS)
	$(CXX) $(LDFLAGS) `freetype-config --libs` -liconv -o $@ $+

tools_gui$(EXEEXT): gui/main.o gui/pages.o gui/gui_tools.o compress_agos.o compress_gob.o compress_kyra.o \
	compress_queen.o compress_saga.o compress_scumm_bun.o compress_scumm_san.o compress_scumm_sou.o \
	compress_sword1.o compress_sword2.o compress_touche.o compress_tucker.o compress_tinsel.o \
	extract_agos.o extract_cine.o extract_gob_stk.o extract_kyra.o extract_loom_tg16.o extract_mm_apple.o \
	extract_mm_c64.o extract_mm_nes.o extract_parallaction.o extract_scumm_mac.o extract_t7g_mac.o \
	encode_dxa.o extract_zak_c64.o kyra_pak.o kyra_ins.o compress.o tool.o tools.o $(UTILS)
	$(CXX) $(LDFLAGS) -o $@ $+ `wx-config --libs` -lpng -lz -lvorbis -logg -lvorbisenc -lFLAC

tools_cli$(EXEEXT): main_cli.o tools_cli.o compress_agos.o compress_gob.o compress_kyra.o \
	compress_queen.o compress_saga.o compress_scumm_bun.o compress_scumm_san.o compress_scumm_sou.o \
	compress_sword1.o compress_sword2.o compress_touche.o compress_tucker.o compress_tinsel.o \
	extract_agos.o extract_cine.o extract_gob_stk.o extract_kyra.o extract_loom_tg16.o extract_mm_apple.o \
	extract_mm_c64.o extract_mm_nes.o extract_parallaction.o extract_scumm_mac.o extract_t7g_mac.o \
	encode_dxa.o extract_zak_c64.o kyra_pak.o kyra_ins.o compress.o tool.o tools.o $(UTILS)
	$(CXX) $(LDFLAGS) -o $@ $+ -lpng -lz -lvorbis -logg -lvorbisenc -lFLAC

sword2_clue$(EXEEXT): sword2_clue.o
	$(CXX) $(LDFLAGS) -o $@ $+ `pkg-config --libs gtk+-2.0`

gui/main.o: gui/main.cpp gui/main.h gui/configuration.h gui/pages.h
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) `wx-config --cxxflags` -c gui/main.cpp -o gui/main.o

gui/pages.o: gui/pages.cpp gui/pages.h gui/main.h gui/gui_tools.h
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) `wx-config --cxxflags` -c gui/pages.cpp -o gui/pages.o

create_sjisfnt.o: create_sjisfnt.cpp util.h
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) `freetype-config --cflags` -c create_sjisfnt.cpp -o create_sjisfnt.o

tools_gui.o: tools_gui.cpp tools_gui.h
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) `wx-config --cxxflags` -c tools_gui.cpp -o tools_gui.o

gui/gui_tools.o: gui/gui_tools.cpp gui/gui_tools.h
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) `wx-config --cxxflags` -c gui/gui_tools.cpp -o gui/gui_tools.o

sword2_clue.o: sword2_clue.cpp
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) `pkg-config --cflags gtk+-2.0` -c sword2_clue.cpp

clean:
	rm -f $(addsuffix *.o,$(MODULE_DIRS)) $(TARGETS)

######################################################################
# The build rules follow - normally you should have no need to
# touch whatever comes after here.
######################################################################

# Concat DEFINES and INCLUDES to form the CPPFLAGS
CPPFLAGS := $(DEFINES) $(INCLUDES)

# Include the build instructions for all modules
#-include $(addprefix $(srcdir)/, $(addsuffix /module.mk,$(MODULES)))

# Depdir information
DEPDIRS = $(addsuffix $(DEPDIR),$(MODULE_DIRS))
DEPFILES =

%.o: %.cpp
	$(MKDIR) $(*D)/$(DEPDIR)
	$(CXX) $(NO_MAIN) -Wp,-MMD,"$(*D)/$(DEPDIR)/$(*F).d",-MQ,"$@",-MP $(CXXFLAGS) $(CPPFLAGS) -c $(<) -o $*.o

# Include the dependency tracking files.
-include $(wildcard $(addsuffix /*.d,$(DEPDIRS)))
