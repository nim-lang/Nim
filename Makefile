# Auto-configuring Makefile for the Nim Programming Language.

srcdir = @srcdir@
objdir = @builddir@
#prefix = @prefix@
#exec_prefix = @exec_prefix@
#bindir = @bindir@
#mandir = @mandir@
PERL = perl
# PERLFLAGS = -I$(srcdir)/perllib -I$(srcdir)
RUNPERL = $(PERL) $(PERLFLAGS)
MANPAGES = @MANPAGES@
NSIS = @NSIS@

PERLREQ = nsis/include/version.nsh

nsis/include/version.nsh: nsis/include/version.pl
  $(RUNPERL) $(srcdir)/nsis/include/version.pl > nsis/include/version.nsh

nsis/include/arch.nsh: nsis/include/get.pl
  $(PERL) $(srcdir)/nsis/include/get.pl > nsis/include/arch.nsh

nsis: nsis/nim-setup.nsi nsis/include/arch.nsh nsis/include/version.nsh
  $(MAKENSIS)
