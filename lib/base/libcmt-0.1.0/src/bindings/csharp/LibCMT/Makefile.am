## Process this file with automake to produce Makefile.in

if LIBCMT_BUILD_CSHARP_BINDING
ASSEMBLY_NAME = LibCMT
ASSEMBLY = $(ASSEMBLY_NAME).dll
TARGET = $(ASSEMBLY)
CLEANFILES = $(ASSEMBLY) generated-stamp
else
ASSEMBLY_NAME =
ASSEMBLY =
TARGET =
CLEANFILES =
endif

noinst_DATA = $(ASSEMBLY)

sources = LibCMT.cs
EXTRA_DIST = $(sources) MainPage.cs Doxyfile \
	libcmt-sharp.snk libcmt-sharp.pub

build_sources = $(addprefix $(srcdir)/, $(sources))

generated-stamp:
	touch generated-stamp

$(ASSEMBLY): $(build_sources) generated-stamp
	echo "$(CSC) /out:$(ASSEMBLY) /target:library $(build_sources)";\
	$(CSC) /target:library /keyfile:$(srcdir)/libcmt-sharp.snk      \
	/out:$(ASSEMBLY) $(build_sources) 

if LIBCMT_USE_GACUTIL
install-data-local:
	@if test -n '$(TARGET)'; then					\
	  echo "$(GACUTIL) /i $(ASSEMBLY) /f $(GACUTIL_FLAGS)";		\
	  $(GACUTIL) /i $(ASSEMBLY) /f $(GACUTIL_FLAGS) || exit 1;	\
	fi
uninstall-local:
	@if test -n '$(TARGET)'; then					\
	  echo "$(GACUTIL) /u $(ASSEMBLY_NAME) $(GACUTIL_FLAGS)";	\
	  $(GACUTIL) /u $(ASSEMBLY_NAME) $(GACUTIL_FLAGS) || exit 1;	\
	fi
else
install-data-local:
	@if test -n '$(TARGET)'; then			                \
	  echo "cp $(ASSEMBLY) $(DESTDIR)$(libdir)";  	                \
	  cp $(ASSEMBLY) $(DESTDIR)$(libdir) || exit 1;	                \
	fi
uninstall-local:
	@if test -n '$(TARGET)'; then			                \
	  echo "rm -f $(DESTDIR)$(libdir)/$(ASSEMBLY)";		 	\
	  rm -f $(DESTDIR)$(libdir)/$(ASSEMBLY) || exit 1; 		\
	fi
endif
