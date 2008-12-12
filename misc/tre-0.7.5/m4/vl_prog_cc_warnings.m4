dnl @synopsis VL_PROG_CC_WARNINGS([ANSI])
dnl
dnl Enables a high level of warnings for the C compiler.  Optionally,
dnl if the first argument is nonempty, turns on flags which enforce and/or
dnl enable proper ANSI C if such are known with the compiler used.
dnl
dnl Currently this macro knows about GCC, Solaris C compiler,
dnl Digital Unix C compiler, C for AIX Compiler, HP-UX C compiler,
dnl IRIX C compiler, NEC SX-5 (Super-UX 10) C compiler, and Cray J90
dnl (Unicos 10.0.0.8) C compiler.
dnl
dnl @version 1.2
dnl @author Ville Laurikari <vl@iki.fi>
dnl
AC_DEFUN([VL_PROG_CC_WARNINGS], [
  # Don't override if CFLAGS was already set.
  if test -z "$ac_env_CFLAGS_set"; then
    ansi=$1
    if test -z "$ansi"; then
      msg="for C compiler warning flags"
    else
      msg="for C compiler warning and ANSI conformance flags"
    fi
    AC_CACHE_CHECK($msg, vl_cv_prog_cc_warnings, [
      if test -n "$CC"; then
        cat > conftest.c <<EOF
int main(int argc, char **argv) { return 0; }
EOF

        dnl GCC
        if test "$GCC" = "yes"; then
          if test -z "$ansi"; then
            vl_cv_prog_cc_warnings="-Wall"
          else
            vl_cv_prog_cc_warnings="-Wall -ansi -pedantic"
          fi

        dnl Most compilers print some kind of a version string with some command
        dnl line options (often "-V").  The version string should be checked
        dnl before doing a test compilation run with compiler-specific flags.
        dnl This is because some compilers (like the Cray compiler) only
        dnl produce a warning message for unknown flags instead of returning
        dnl an error, resulting in a false positive.  Also, compilers may do
        dnl erratic things when invoked with flags meant for a different
        dnl compiler.

        dnl Solaris C compiler
        elif $CC -V 2>&1 | grep -i "WorkShop" > /dev/null 2>&1 &&
             $CC -c -v -Xc conftest.c > /dev/null 2>&1 &&
             test -f conftest.o; then
          if test -z "$ansi"; then
            vl_cv_prog_cc_warnings="-v"
          else
            vl_cv_prog_cc_warnings="-v -Xc"
          fi

        dnl Compaq (formerly Digital Unix) C compiler
        elif ($CC -V 2>&1 | grep -i "Digital UNIX Compiler" > /dev/null 2>&1 ||
              $CC -V 2>&1 | grep -i "Compaq C" > /dev/null 2>&1) &&
             $CC -c -verbose -w0 -warnprotos -std1 conftest.c > /dev/null 2>&1 &&
             test -f conftest.o; then
          if test -z "$ansi"; then
            vl_cv_prog_cc_warnings="-verbose -w0 -warnprotos"
          else
            vl_cv_prog_cc_warnings="-verbose -w0 -warnprotos -std1"
          fi

        dnl C for AIX Compiler
        elif $CC 2>&1 | grep -i "C for AIX Compiler" > /dev/null 2>&1 &&
	     $CC -c -qlanglvl=ansi -qinfo=all conftest.c > /dev/null 2>&1 &&
             test -f conftest.o; then
          if test -z "$ansi"; then
            vl_cv_prog_cc_warnings="-qsrcmsg -qinfo=all:noppt:noppc:noobs:nocnd:nouni:nocnv"
          else
            vl_cv_prog_cc_warnings="-qsrcmsg -qinfo=all:noppt:noppc:noobs:nocnd:nouni:nocnv -qlanglvl=ansi"
          fi

        dnl IRIX C compiler
        elif $CC -version 2>&1 | grep -i "MIPSpro Compilers" > /dev/null 2>&1 &&
             $CC -c -fullwarn -ansi -ansiE conftest.c > /dev/null 2>&1 &&
             test -f conftest.o; then
          if test -z "$ansi"; then
            vl_cv_prog_cc_warnings="-fullwarn"
          else
            vl_cv_prog_cc_warnings="-fullwarn -ansi -ansiE"
          fi

        dnl HP-UX C compiler
        elif what $CC 2>&1 | grep -i "HP C Compiler" > /dev/null 2>&1 &&
             $CC -c -Aa +w1 conftest.c > /dev/null 2>&1 &&
             test -f conftest.o; then
          if test -z "$ansi"; then
            vl_cv_prog_cc_warnings="+w1"
          else
            vl_cv_prog_cc_warnings="+w1 -Aa"
          fi

        dnl The NEC SX-5 (Super-UX 10) C compiler
        elif $CC -V 2>&1 | grep "/SX" > /dev/null 2>&1 &&
             $CC -c -pvctl[,]fullmsg -Xc conftest.c > /dev/null 2>&1 &&
             test -f conftest.o; then
          if test -z "$ansi"; then
            vl_cv_prog_cc_warnings="-pvctl[,]fullmsg"
          else
            vl_cv_prog_cc_warnings="-pvctl[,]fullmsg -Xc"
          fi

        dnl The Cray C compiler (Unicos)
        elif $CC -V 2>&1 | grep -i "Cray" > /dev/null 2>&1 &&
             $CC -c -h msglevel 2 conftest.c > /dev/null 2>&1 &&
             test -f conftest.o; then
          if test -z "$ansi"; then
            vl_cv_prog_cc_warnings="-h msglevel 2"
          else
            vl_cv_prog_cc_warnings="-h msglevel 2 -h conform"
          fi

        fi
        rm -f conftest.*
      fi
      if test -n "$vl_cv_prog_cc_warnings"; then
        CFLAGS="$CFLAGS $vl_cv_prog_cc_warnings"
      else
        vl_cv_prog_cc_warnings="unknown"
      fi
    ])
  fi
])dnl
