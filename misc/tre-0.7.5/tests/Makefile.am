## Process this file with automake to produce Makefile.in

SUBDIRS = agrep

check_PROGRAMS = retest randtest test-str-source
EXTRA_PROGRAMS = bench
LDADD = ../gnulib/lib/libgnu.la $(LTLIBINTL)

retest_SOURCES = retest.c

randtest_SOURCES = randtest.c

bench_SOURCES = bench.c
bench_LDADD = ../lib/libtre.la $(LDADD) -lm

test_str_source_SOURCES = test-str-source.c
test_str_source_LDADD = ../lib/libtre.la $(LDADD) -lm

if TRE_DEBUG
  retest_LDADD = ../lib/libtre.la $(LDADD)
  randtest_LDADD = ../lib/libtre.la $(LDADD)
else !TRE_DEBUG
  ## Debugging is not turned on.  Make a malloc-debugging version of the
  ## library and use it with `retest' and `randtest'.  Malloc-debugging is
  ## not used for the debugging version since it would just get in the way.
  check_LTLIBRARIES = libxtre.la
  libxtre_la_SOURCES =			\
	../lib/tre-mem.c		\
	../lib/tre-stack.c		\
	../lib/tre-ast.c		\
	../lib/tre-parse.c		\
	../lib/tre-compile.c		\
	../lib/tre-match-parallel.c	\
	../lib/tre-match-backtrack.c	\
	../lib/regcomp.c		\
	../lib/regexec.c		\
	../lib/regerror.c		\
	../lib/xmalloc.c
if TRE_APPROX
  libxtre_la_SOURCES += ../lib/tre-match-approx.c
endif TRE_APPROX
  libxtre_la_CFLAGS = -DMALLOC_DEBUGGING

  retest_CFLAGS = -DMALLOC_DEBUGGING
  retest_LDADD = libxtre.la $(LDADD)
  randtest_CFLAGS = -DMALLOC_DEBUGGING
  randtest_LDADD = libxtre.la $(LDADD)
endif !TRE_DEBUG

INCLUDES = -I$(top_srcdir)/lib -I$(top_srcdir)/gnulib/lib

EXTRA_DIST = build-tests.sh

TESTS = test-str-source retest
