
if !TRE_DEBUG
if TRE_AGREP
TESTS = run-tests.sh
endif TRE_AGREP
endif !TRE_DEBUG

TESTS_ENVIRONMENT = \
  top_builddir=$(top_builddir) \
  host_triplet=$(host_triplet)
EXTRA_DIST = run-tests.sh

dist-hook:
	cp -p $(srcdir)/*.args $(srcdir)/*.ok $(srcdir)/*.input $(distdir)

CLEANFILES = *.out
