## Process this file with automake to produce Makefile.in

SUBDIRS = bindings

lib_LTLIBRARIES = libcmt.la

libdir = $(prefix)/lib
datadir = $(prefix)/share

AM_CFLAGS = @CFLAGS@ @LIBCMT_CFLAGS@

libcmt_la_LDFLAGS = -export-dynamic -avoid-version
libcmt_la_LIBADD = @LIBCMT_LIBS@

library_includedir = $(includedir)/cmt
library_include_HEADERS = cmt.h gtransaction.h
libcmt_la_SOURCES = gtransaction.c

INCLUDES = -I$(top_srcdir)/src -I$(top_builddir)

#EXTRA_DIST = 
