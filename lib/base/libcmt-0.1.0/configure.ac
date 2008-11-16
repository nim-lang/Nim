## Process this file with autoconf to produce a configure script.

AC_PREREQ(2.57)
AC_INIT(Composable Memory Transactions Library for C, 0.1.0, dprotti@users.sourceforge.net, [libcmt])
AM_INIT_AUTOMAKE([1.7.0 dist-bzip2])

AC_CONFIG_HEADER(config.h)

AC_PREFIX_PROGRAM(mcs)

AC_PATH_PROG(PKG_CONFIG, [pkg-config], [no])
if test x$PKG_CONFIG = xno ; then
  AC_MSG_ERROR([*** pkg-config not found. See http://www.freedesktop.org/software/pkgconfig/])
fi
if $PKG_CONFIG --atleast-pkgconfig-version 0.14 ; then
  :
else
  AC_MSG_ERROR([*** pkg-config too old; version 0.14 or better required.])
fi

if test x"$GCC" = xyes; then
  CFLAGS="$CFLAGS -Wall -Wimplicit -Wunused -Wmissing-prototypes"
fi

# Misc messages
CS="C#"
LIBCMT_MSG_NO_GACUTIL="
        No gacutil tool found, LibCMT will not be installed on the Global Assembly Cache.
        However, LibCMT assembly will still be usable. You can obtain the required arguments
        for the $CS compiler with 'pkg-config libcmt-sharp --libs'."

# Check for dependencies before anything else.
LIBCMT_PKG_CONFIG_DEP="glib-2.0 gthread-2.0"

PKG_CHECK_MODULES(LIBCMT, ${LIBCMT_PKG_CONFIG_DEP} >= 2.4.0,,exit)
AC_SUBST(LIBCMT_LIBS)
AC_SUBST(LIBCMT_CFLAGS)
AC_SUBST(LIBCMT_PKG_CONFIG_DEP)

# C# binding stuff. Here because of the above: to check dependencies early.
AC_ARG_ENABLE(csharp_binding,
              [AC_HELP_STRING([--enable-csharp-binding],
                              [build C# binding [default=disabled]])],,
              [csharp_binding=disabled])
AC_ARG_ENABLE(gacutil,
              [AC_HELP_STRING([--enable-gacutil],
                              [use gacutil tool to install the .Net assembly [default=enabled]])],,
              [gacutil=enabled])

libcmt_build_csharp_binding="yes"
libcmt_have_gacutil="true"
AC_MSG_CHECKING([whether to build $CS binding])
if test "x$csharp_binding" = "xdisabled"; then
  AC_MSG_RESULT([no])
  libcmt_build_csharp_binding="no"
  libcmt_have_gacutil="false"
else
  AC_MSG_RESULT([yes])
  MONO_REQUIRED_VERSION=0.31
  PKG_CHECK_MODULES(MONO_DEPENDENCY, mono >= $MONO_REQUIRED_VERSION, has_mono=true, has_mono=false)
  if test "x$has_mono" = "xtrue"; then
    GACUTIL_FLAGS='/package LibCMT /root $(DESTDIR)$(libdir)'
    GENERATED_SOURCES=generated/*.cs
    AC_PATH_PROG(CSRUNTIME, mono, no)
    AC_PATH_PROG(CSC, mcs, no)
    if test `uname -s` = "Darwin"; then
	LIB_PREFIX=
	LIB_SUFFIX=.dylib
    else
	LIB_PREFIX=.so
	LIB_SUFFIX=
    fi
  else
    AC_PATH_PROG(CSC, csc.exe, no)
    GACUTIL_FLAGS=
    GENERATED_SOURCES=generated\\\\*.cs
    if test x$CSC = "xno"; then
      AC_MSG_WARN([You need to install either mono or .Net to build the $CS binding])
    else
      CSRUNTIME=
      LIB_PREFIX=
      LIB_SUFFIX=.dylib
    fi
  fi

  if test "x$CSC" = "xno" ; then
    AC_MSG_WARN([No $CS compiler found, needed to build $CS binding])
    libcmt_build_csharp_binding="no"
  fi

  AC_PATH_PROG(GACUTIL, gacutil, no)
  if test "x$GACUTIL" = "xno" ; then
    AC_MSG_WARN([$LIBCMT_MSG_NO_GACUTIL])
    libcmt_have_gacutil="false"
  fi
  AC_MSG_CHECKING([whether to use the gacutil tool to install the assembly])
  if test "x$gacutil" = "xenabled"; then
    AC_MSG_RESULT([yes])
  else
    AC_MSG_RESULT([no])
  fi

  AC_SUBST(CSRUNTIME)
  AC_SUBST(CSC)
  AC_SUBST(GACUTIL)
  AC_SUBST(GACUTIL_FLAGS)
  AC_SUBST(LIB_PREFIX)
  AC_SUBST(LIB_SUFFIX)
  AC_SUBST(GENERATED_SOURCES)
fi
AM_CONDITIONAL(LIBCMT_BUILD_CSHARP_BINDING, test x$libcmt_build_csharp_binding = xyes)
AM_CONDITIONAL(LIBCMT_USE_GACUTIL, test x$gacutil = xenabled && test x$libcmt_have_gacutil = xtrue)

# Check for programs.
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_LIBTOOL

# Check for header files.
AC_HEADER_STDC
AC_CHECK_HEADERS([libintl.h locale.h stdlib.h string.h unistd.h setjmp.h])

# Check for typedefs, structures, and compiler characteristics.
#AC_C_VOLATILE
#AC_C_CONST
#AC_C_INLINE
	    
# Check for library functions.
AC_CHECK_FUNCS([siglongjmp])

# Arguments to specify certain features.
AC_ARG_ENABLE(checks,
              [AC_HELP_STRING([--disable-checks],
                              [turn off checks (non-nullary for arguments and other stuff) [default=enabled]])],,
              [checks=enabled])
AC_ARG_ENABLE(save_signal_mask,
              [AC_HELP_STRING([--enable-save-signal-mask],
                              [turn on signal mask saving on sigsetjmp() (turn it off only if you REALLY know what you are doing) [default=enabled]])],,
              [save_signal_mask=enabled])
AC_ARG_ENABLE(debug,
              [AC_HELP_STRING([--enable-debug],
                           [turn on debug mode [default=disabled]])],,
	      [debug=disabled])
AC_ARG_ENABLE(gc_friendly,
              [AC_HELP_STRING([--enable-gc-friendly],
                              [turn on garbage collector friendliness [default=disabled]])],,
              [gc_friendly=disabled])

AC_MSG_CHECKING([whether to disable checks])
if test "x$checks" = "xenabled"; then
  AC_MSG_RESULT([no])
else
  AC_DEFINE(G_DISABLE_CHECKS, 1, [Whether to disable checks])
  AC_MSG_RESULT([yes])
fi

AC_MSG_CHECKING([whether to save the signal mask on sigsetjmp()])
if test "x$save_signal_mask" = "xenabled"; then
  AC_DEFINE(LIBCMT_SAVE_SIGNAL_MASK, 1, [Whether to save the signal mask of the process])
  AC_MSG_RESULT([yes])
else
  AC_DEFINE(LIBCMT_SAVE_SIGNAL_MASK, 0, [Whether to save the signal mask of the process])
  AC_MSG_RESULT([no])
fi

AC_MSG_CHECKING([whether to activate debugging])
if test "x$debug" = "xdisabled"; then
  AC_MSG_RESULT([no])
else
  AC_MSG_RESULT([yes])
  AC_DEFINE([LIBCMT_DEBUG], [1], [Activate LibCMT's debugging])
fi

AC_MSG_CHECKING([whether to enable garbage collector friendliness])
if test "x$gc_friendly" = "xdisabled"; then
  AC_MSG_RESULT([no])
else
  AC_DEFINE(ENABLE_GC_FRIENDLY, 1, [Whether to enable GC friendliness])
  AC_SUBST(ENABLE_GC_FRIENDLY)
  AC_MSG_RESULT([yes])
fi

# Internationalization
#ALL_LINGUAS="es es_AR"
#GETTEXT_PACKAGE=libcmt
#AC_SUBST(GETTEXT_PACKAGE)
#AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE,"$GETTEXT_PACKAGE", [GETTEXT package name])
#AM_GLIB_GNU_GETTEXT
#AC_PROG_INTLTOOL

AC_CONFIG_FILES([Makefile
                 libcmt.pc
                 libcmt-sharp.pc
                 src/Makefile
                 src/bindings/Makefile
                 src/bindings/csharp/Makefile
                 src/bindings/csharp/LibCMT/Makefile
                 src/bindings/csharp/tests/Makefile
                 tests/Makefile
                 tests/one-tvar/Makefile
                 tests/many-tvars/Makefile
                 tests/classic/Makefile])
#		 po/Makefile.in
AC_OUTPUT

echo "
=========================
CMT Library version $VERSION
=========================

Install path           : ${prefix}/lib/
Compiler               : ${CC}
Debug                  : ${debug}
Build ${CS} binding       : ${libcmt_build_csharp_binding}
"
