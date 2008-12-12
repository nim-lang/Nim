dnl Process this file with autoconf to produce a configure script.
AC_INIT(TRE, 0.7.5, [tre-general@lists.laurikari.net])
AC_CONFIG_SRCDIR([lib/regcomp.c])
AC_CONFIG_AUX_DIR(utils)
AC_CANONICAL_TARGET
AM_INIT_AUTOMAKE(1.9.0)
AC_PREREQ(2.59)
AM_GNU_GETTEXT_VERSION(0.14.3)

dnl Checks for programs.
AC_PROG_CC
gl_EARLY
AC_PROG_CPP
AC_PROG_INSTALL

tre_version_1=`echo $PACKAGE_VERSION | cut -d . -f 1`
tre_version_2=`echo $PACKAGE_VERSION | cut -d . -f 2`
tre_version_3=`echo $PACKAGE_VERSION | cut -d . -f 3`
tre_version=$tre_version_1.$tre_version_2.$tre_version_3
AC_DEFINE_UNQUOTED(TRE_VERSION,  "$tre_version",  [ TRE version string.  ])
AC_DEFINE_UNQUOTED(TRE_VERSION_1, $tre_version_1, [ TRE version level 1. ])
AC_DEFINE_UNQUOTED(TRE_VERSION_2, $tre_version_2, [ TRE version level 2. ])
AC_DEFINE_UNQUOTED(TRE_VERSION_3, $tre_version_3, [ TRE version level 3. ])
AC_SUBST(TRE_VERSION, $tre_version)

dnl Options
AC_ARG_ENABLE(profile,
  AC_HELP_STRING([--enable-profile],
                 [enable profiling with gprof @<:@default=disabled@:>@]),
  [ tre_profile="$enableval" ],
  [ tre_profile="no" ])

AC_ARG_ENABLE(debug,
  AC_HELP_STRING(
    [--enable-debug],
    [enable development-time debugging @<:@default=disabled@:>@]),
  [ tre_debug="$enableval" ],
  [ tre_debug="no" ])
if test "$tre_debug" = "yes"; then
  AM_CONDITIONAL(TRE_DEBUG, true)
  AC_DEFINE(TRE_DEBUG, 1,
    [ Define if you want TRE to print debug messages to stdout. ])
else
  AM_CONDITIONAL(TRE_DEBUG, false)
  AC_DEFINE(NDEBUG, 1, [ Define if you want to disable debug assertions. ])
fi

if test "$tre_profile" = "yes"; then
  CFLAGS="$CFLAGS -pg"
  AM_CONDITIONAL(TRE_PROFILE, true)
else
  AM_CONDITIONAL(TRE_PROFILE, false)
fi

AC_ARG_ENABLE(warnings,
  AC_HELP_STRING(
    [--disable-warnings],
    [disable C compiler warning messages @<:@default=enabled@:>@]),
  [ tre_cc_warnings="$enableval" ],
  [ tre_cc_warnings="yes" ])
if test "$tre_cc_warnings" = "yes"; then
  VL_PROG_CC_WARNINGS()
fi

AC_ARG_ENABLE(approx,
  AC_HELP_STRING(
    [--disable-approx],
    [disable the approximate matching functionality @<:@default=enabled@:>@]),
  [ tre_approx="$enableval" ],
  [ tre_approx="yes" ])
if test "$tre_approx" = "yes"; then
  AC_DEFINE(TRE_APPROX, 1,
    [ Define if you want to enable approximate matching functionality. ])
  AM_CONDITIONAL(TRE_APPROX, true)
else
  AM_CONDITIONAL(TRE_APPROX, false)
fi

if test "$tre_approx" = "yes"; then
  AC_ARG_ENABLE(agrep,
    AC_HELP_STRING([--disable-agrep],
      [Do not build and install the agrep tool @<:@default=install@:>@]),
    [ tre_agrep="$enableval" ],
    [ tre_agrep="yes" ])
else
  tre_agrep="no (requires approximate matching)"
fi

if test "$tre_agrep" = "yes"; then
  AM_CONDITIONAL(TRE_AGREP, true)
else
  AM_CONDITIONAL(TRE_AGREP, false)
fi


dnl Checks for compiler characteristics.
AC_C_CONST
AC_C_INLINE

dnl Checks for headers, functions, types, and macros
AC_DEFINE(_GNU_SOURCE, 1, [ Define to enable GNU extensions in glibc ])
AC_HEADER_STDC

gl_INIT
gl_HEADER_UNISTD
gl_GETOPT

AC_ARG_WITH(alloca,
  AC_HELP_STRING(
    [--without-alloca],
    [don't use alloca  @<:@default=use@:>@]),
  [ tre_use_alloca="$withval" ],
  [ tre_use_alloca="yes" ])
if test "$tre_use_alloca" = "yes"; then
  ALLOCA=""
  AC_FUNC_ALLOCA
  if test -z "$ALLOCA"; then
    # alloca() works.
    AC_DEFINE(TRE_USE_ALLOCA, 1,
      [ Define if you want TRE to use alloca() instead of malloc() when
        allocating memory needed for regexec operations. ])
  fi
fi

AC_ARG_ENABLE(system-abi,
  AC_HELP_STRING(
    [--enable-system-abi],
    [try to make TRE compatible with the system \
regex ABI  @<:@default=disabled@:>@]),
  [ tre_system_abi="$enableval" ],
  [ tre_system_abi="no" ])

# If we are building a version compatible with the system ABI, we need to
# find an absolute path to the system regex.h (so it can be included from
# TRE regex.h using `#include "/path/to/regex.h"').  Then we need to
# find a field in the system defined regex_t struct where a pointer to
# the compiled regex object can be stored.

if test "$tre_system_abi" = "yes"; then
  # Check that there is a system regex.h to begin with.  We may need
  # to include sys/types.h before regex.h, so check for that first.
  AC_CHECK_HEADERS([sys/types.h])
  AC_CHECK_HEADERS([regex.h], [],
    [ tre_system_abi="no (regex.h not found)" ],
    [#if HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
])
fi

if test "$tre_system_abi" = "yes"; then
  # Find out where system regex.h is.  This is done by running the C
  # preprocessor and grepping its output, hopefully getting a full
  # path to regex.h.
  AC_MSG_CHECKING([path to system regex.h])
  echo '#include <regex.h>' > conftest.c
  tre_system_regex_h=`$CPP conftest.c \
    | grep '^#[a-z]* [0-9]* "\(.*regex.h\)"' \
    | head -1 \
    | sed 's/^#[a-z]* [0-9]* \"\(.*\)\".*/\1/'`
  rm -f conftest.c
  if test -n "$tre_system_regex_h" && test -f "$tre_system_regex_h"; then
    AC_MSG_RESULT($tre_system_regex_h)
  else
    AC_MSG_RESULT(unknown)
    tre_system_abi="no (could determine path to systeg regex.h)"
  fi
fi

if test "$tre_system_abi" = "yes"; then
  # Find a field in the system regex_t struct where we can store a pointer.
  # This is done by trying several names that are known to work on different
  # systems.
  AC_MSG_CHECKING([for a usable field for a pointer in regex_t])
  tre_regex_t_field=""
  for field in buffer re_comp __re_comp __reg_expression \
               re_g "re_pad@<:@0@:>@"; do
    if test -z "$tre_regex_t_field"; then
      AC_COMPILE_IFELSE(
        [ AC_LANG_PROGRAM([
#include <sys/types.h>
#include <regex.h>
      ],
      [
    regex_t foo;
    void *bar = foo.$field;
    foo.$field = bar;
      ])],
        [ AC_MSG_RESULT($field)
          tre_regex_t_field="$field" ])
    fi
  done
  if test -z "$tre_regex_t_field"; then
    AC_MSG_RESULT(no)
    tre_system_abi="no (unknown regex_t contents, report to \
$PACKAGE_BUGREPORT)"
  fi
fi

if test "$tre_system_abi" = "yes"; then
  # So far, so good.  Now check if we can redefine the system regex
  # functions.  For example, the system headers may define the
  # standard functions as static wrapper functions (like on IRIX)
  # which prevents redefining them later.

  # IRIX has some macro magic which we need to turn off.
  AC_DEFINE(_REGCOMP_INTERNAL, 1, [ Define on IRIX ])
  AC_MSG_CHECKING([if POSIX regex functions can be redefined])
  AC_COMPILE_IFELSE(
        [ AC_LANG_PROGRAM([
#include <sys/types.h>
#include <regex.h>

int
regcomp(regex_t *preg, const char *regex, int cflags)
{
  return 0;
}
void
regfree(regex_t *preg)
{
  return;
}
int
regexec(const regex_t *preg, const char *str,
        size_t nmatch, regmatch_t pmatch@<:@@:>@, int eflags)
{
  return 0;
}
size_t
regerror(int errcode, const regex_t *preg, char *errbuf,
	 size_t errbuf_size)
{
  return 0;
}
      ])],
        [ AC_MSG_RESULT(yes)
          tre_system_abi="yes" ],
        [ AC_MSG_RESULT(no)
          tre_system_abi="no (unable to redefine system functions)" ])
fi

if test "$tre_system_abi" = "yes"; then
  # Great, everything seems to be OK for ABI compatibility.  Just check
  # some additional types that may or may not be defined, and set up
  # variables to enable ABI compatibility in regex.h.

  AC_CHECK_TYPES([reg_errcode_t],,,[
#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif /* HAVE_SYS_TYPES_H */
#ifdef HAVE_REGEX_H
#include <regex.h>
#endif /* HAVE_REGEX_H */
    ])

  AC_DEFINE(TRE_USE_SYSTEM_REGEX_H, 1,
    [ Define to include the system regex.h from TRE regex.h ])
  AC_DEFINE_UNQUOTED(TRE_SYSTEM_REGEX_H_PATH, "$tre_system_regex_h",
    [ Define to the absolute path to the system regex.h ])
  AC_DEFINE_UNQUOTED(TRE_REGEX_T_FIELD, $tre_regex_t_field,
    [ Define to a field in the regex_t struct where TRE should store a
      pointer to the internal tre_tnfa_t structure ])
else
  AC_DEFINE(TRE_REGEX_T_FIELD, value)
fi

AC_CHECK_FUNCS([isascii isblank])

dnl Check whether wide character support should be enabled.
AC_ARG_ENABLE(wchar,
  AC_HELP_STRING(
    [--disable-wchar],
    [disable the wide character (wchar_t) support   @<:@default=detect@:>@]),
  [ tre_enable_wchar="$enableval" ],
  [ tre_enable_wchar="detect" ])

dnl Check whether libutf8 location has been given.
AC_ARG_WITH(libutf8,
  AC_HELP_STRING(
    [--with-libutf8@<:@=DIR@:>@],
    [search for libutf8 from DIR/include and DIR/lib])
AC_HELP_STRING(
    [--without-libutf8],
    [do not use libutf8 @<:@default=use if needed@:>@]),
  [ if test "$with_val" = "no"; then
      tre_libutf8="no"
    else
      tre_libutf8="yes"
      tre_libutf8_dirs="$with_libutf8"
      tre_libutf8_libs="-lutf8"
    fi ],
  [ tre_libutf8="detect"
    tre_libutf8_dirs="none /usr /usr/local"
    tre_libutf8_libs="none -lutf8" ])


if test "$tre_enable_wchar" != "no"; then

  dnl Wide character support is requested.  Check if we need libutf8.
  old_libs="$LIBS"
  old_ldflags="$LDFLAGS"
  old_cppflags="$CPPFLAGS"
  if test "$tre_libutf8" != "no"; then
    AC_MSG_CHECKING([for libutf8])
    found="no"
    dnl Go through directories in $tre_libutf8_dirs for CPPFLAGS and LDFLAGS.
    for try_dir in $tre_libutf8_dirs; do
      if test "$try_dir" = "none"; then
        LDFLAGS="$old_ldflags"
        CPPFLAGS="$old_cppflags"
      else
        LDFLAGS="$old_ldflags -L$try_dir/lib"
        CPPFLAGS="$old_cppflags -I$try_dir/include"
      fi
      dnl Go through libs in $tre_libutf8_libs.
      for try_lib in $tre_libutf8_libs; do
        if test "$try_lib" = "none"; then
          LIBS="$old_libs"
        else
          LIBS="$try_lib $old_libs"
        fi
        dnl Check if mbrtowc or utf8_mbrtowc is available with the current
	dnl CPPFLAGS, LDFLAGS, and LIBS.
        AC_LINK_IFELSE([AC_LANG_CALL([],[mbrtowc])],[found="yes"])
        if test "$found" = "yes"; then
          break;
        fi
        AC_LINK_IFELSE([AC_LANG_CALL([],[utf8_mbrtowc])],[found="yes"])
        if test "$found" = "yes"; then
          break;
        fi
      done
      if test "$found" = "yes"; then
        break;
      fi
    done

    dnl Report results.
    if test "$found" = "yes"; then
      if test "$LIBS" = "$old_libs"; then
        AC_MSG_RESULT([not needed])
        tre_libutf8="no"
      else
        AC_MSG_RESULT([using from $try_dir/{lib,include}])
        tre_libutf8="yes"
      fi
    else
      LIBS="$old_libs"
      LDFLAGS="$old_ldflags"
      CPPFLAGS="$old_cppflags"
      if test "$tre_libutf8" = "detect"; then
        AC_MSG_RESULT([no])
        tre_libutf8="no"
      else
        # Fail if libutf8 was requested but was not found.
        AC_MSG_ERROR([not found])
      fi
    fi
  fi

  if test "$tre_libutf8" = "yes"; then
    dnl We do need libutf8, use the libutf8 headers.
    tre_wchar="yes"
    AC_CHECK_HEADERS([libutf8.h])
  else
    dnl Use the POSIX headers.
    AC_CHECK_HEADERS([wchar.h wctype.h])
  fi

else
  tre_wchar_reason="disabled with --disable-wchar"
  tre_wchar="no ($tre_wchar_reason)"
fi


tre_includes="
#ifdef HAVE_WCHAR_H
#include <wchar.h>
#endif /* HAVE_WCHAR_H */
#ifdef HAVE_WCTYPE_H
#include <wctype.h>
#endif /* HAVE_WCTYPE_H */
#ifdef HAVE_LIBUTF8_H
#include <libutf8.h>
#endif /* HAVE_LIBUTF8_H */
"

if test "$tre_enable_wchar" != "no"; then
  dnl We need wchar_t and WCHAR_MAX
  AC_CHECK_TYPES([wchar_t],
    [ tre_wchar="yes"
      AX_DECL_WCHAR_MAX ],
    [ tre_wchar_reason="wchar_t type not found"
      tre_wchar="no ($tre_wchar_reason)" ],
    [ $tre_includes ])

  if test "$tre_wchar" = "yes"; then
    dnl We need wint_t
    AC_CHECK_TYPES([wint_t],,
      [ tre_wchar_reason="wint_t type not found"
        tre_wchar="no ($tre_wchar_reason)" ],
      [ $tre_includes ])
  fi

  if test "$tre_wchar" = "yes"; then
    dnl We may need mbstate_t
    AC_CHECK_TYPES([mbstate_t],,,[ $tre_includes ])
  fi

  if test "$tre_wchar" = "yes"; then
    dnl We need either wcsrtombs (preferred) or wcstombs
    found="no"
    AX_CHECK_FUNCS_COMP([wcsrtombs wcstombs],[found="yes"; break],,
                        [$tre_includes])
    if test "$found" = "no"; then
      tre_wchar_reason="no wcsrtombs or wcstombs found"
      tre_wchar="no ($tre_wchar_reason)"
    fi
  fi

  if test "$tre_wchar" = "yes"; then
    dnl We need all these
    AX_CHECK_FUNCS_COMP([iswlower iswupper towlower towupper wcschr \
                         wcscpy wcslen wcsncpy],
      [ tre_wchar="yes" ],
      [ tre_wchar_reason="$ac_func not found"
        tre_wchar="no ($tre_wchar_reason)"
        break ],
      [ $tre_includes ])
  fi
fi

case $host in
  *-mingw*)
    dnl wcsrtombs and wcstombs don't seem to work at all on MinGW.
    if test "$tre_libutf8" != "yes"; then
      tre_wchar_reason="Not supported on MinGW"
      tre_wchar="no ($tre_wchar_reason)"
    fi
    ;;
esac

# Fail if wide character support was specifically requested but is
# not supported on this system.
if test "$tre_enable_wchar" = "yes"; then
  if test "$tre_wchar" != "yes"; then
    AC_MSG_ERROR([Cannot enable wide character support: $tre_wchar_reason])
  fi
fi

if test "$tre_wchar" = "yes"; then
  AC_DEFINE(TRE_WCHAR, 1,
    [ Define to enable wide character (wchar_t) support. ])

  dnl We make use of these if they exist.
  AX_CHECK_FUNCS_COMP([wctype iswctype],,,[$tre_includes])
  AX_CHECK_FUNCS_COMP([iswascii iswblank],,,[$tre_includes])
fi

dnl Check for multibyte character set support
AC_ARG_ENABLE(multibyte,
  AC_HELP_STRING(
    [--disable-multibyte],
    [disable multibyte character set support @<:@default=detect@:>@]),
  [ tre_enable_multibyte="$enableval" ],
  [ tre_enable_multibyte="detect" ])

dnl Wide character support is required for multibyte character set support
if test "$tre_wchar" != "yes"; then
  if test "$tre_enable_multibyte" = "yes"; then
    AC_MSG_ERROR([Cannot enable multibyte character support because wide \
character support is not enabled ($tre_wchar_reason)])
  fi
fi

if test "$tre_enable_multibyte" != "no"; then
  if test "$tre_wchar" != "yes"; then
    tre_multibyte="no (requires wide character support)"
  else
    found="no"
    dnl We need either mbrtowc (preferred) or mbtowc
    AX_CHECK_FUNCS_COMP([mbrtowc mbtowc],[found="yes"; break],,[$tre_includes])
    if test "$found" = "no"; then
      tre_mbs_reason="no mbrtowc or mbtowc found"
      tre_multibyte="no ($tre_mbs_reason)"
    else
      tre_multibyte="yes"
    fi
  fi
else
  tre_multibyte="no (disabled with --disable-multibyte)"
fi

# Fail if multibyte character set support was specifically requested but
# is not supported on this system.
if test "$tre_enable_multibyte" = "yes"; then
  if test "$tre_multibyte" != "yes"; then
    AC_MSG_ERROR([Cannot enable multibyte character set support: \
$tre_mbs_reason])
  fi
fi

if test "$tre_multibyte" = "yes"; then
  AC_DEFINE(TRE_MULTIBYTE, 1,
    [ Define to enable multibyte character set support. ])
fi

AC_SYS_LARGEFILE

AM_GNU_GETTEXT([external])
AC_LIBTOOL_TAGS([])
AC_LIBTOOL_WIN32_DLL
AM_DISABLE_STATIC
AC_PROG_LIBTOOL

dnl Output files
AC_CONFIG_HEADERS([config.h lib/tre-config.h])
AC_CONFIG_FILES([
Makefile
doc/Makefile
doc/agrep.1
gnulib/Makefile
gnulib/lib/Makefile
gnulib/tests/Makefile
lib/Makefile
m4/Makefile
po/Makefile.in
src/Makefile
tests/Makefile
tests/agrep/Makefile
tre.pc
tre.spec
utils/Makefile
])
AC_OUTPUT


dnl Print configuration summary

cat <<EOF


Configuration summary
=====================

TRE is now configured as follows:

* Compilation environment

  CC       = $CC
  CFLAGS   = $CFLAGS
  CPP      = $CPP
  CPPFLAGS = $CPPFLAGS
  LD       = $LD
  LDFLAGS  = $LDFLAGS
  LIBS     = $LIBS
  Use alloca():                       $tre_use_alloca

* TRE options

  Development-time debugging:         $tre_debug
  System regex ABI compatibility:     $tre_system_abi
  Wide character (wchar_t) support:   $tre_wchar
  Multibyte character set support:    $tre_multibyte
  Approximate matching support:       $tre_approx
  Build and install agrep:            $tre_agrep

EOF
