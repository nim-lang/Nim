## Process this file with automake to produce Makefile.in

lib_LTLIBRARIES = libtre.la
libtre_la_LDFLAGS = -no-undefined -version-info 6:4:2 $(LDFLAGS)
libtre_la_LIBADD = $(LTLIBINTL)

noinst_HEADERS =		\
	tre-ast.h		\
	tre-compile.h		\
	tre-internal.h		\
	tre-match-utils.h	\
	tre-mem.h		\
	tre-parse.h		\
	tre-stack.h		\
	xmalloc.h

libtre_la_SOURCES =		\
	tre-ast.c		\
	tre-compile.c		\
	tre-match-backtrack.c	\
	tre-match-parallel.c	\
	tre-mem.c		\
	tre-parse.c		\
	tre-stack.c		\
	regcomp.c		\
	regexec.c		\
	regerror.c

INCLUDES = -I$(top_srcdir)/gnulib/lib

if TRE_APPROX
libtre_la_SOURCES += tre-match-approx.c
endif TRE_APPROX

dist_pkginclude_HEADERS = regex.h
nodist_pkginclude_HEADERS = tre-config.h
