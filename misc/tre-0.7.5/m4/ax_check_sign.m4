dnl @synopsis AX_CHECK_SIGN (TYPE, [ACTION-IF-SIGNED], [ACTION-IF-UNSIGNED], [INCLUDES])
dnl
dnl Checks whether TYPE is signed or not.  If no INCLUDES are specified,
dnl the default includes are used.  If ACTION-IF-SIGNED is given, it is
dnl additional shell code to execute when the type is signed.  If
dnl ACTION-IF-UNSIGNED is given, it is executed when the type is unsigned.
dnl
dnl This macro assumes that the type exists.  Therefore the existence of
dnl the type should be checked before calling this macro.  For example:
dnl
dnl   AC_CHECK_HEADERS([wchar.h])
dnl   AC_CHECK_TYPE([wchar_t],,[ AC_MSG_ERROR([Type wchar_t not found.]) ])
dnl   AX_CHECK_SIGN([wchar_t],
dnl     [ AC_DEFINE(WCHAR_T_SIGNED, 1, [Define if wchar_t is signed]) ],
dnl     [ AC_DEFINE(WCHAR_T_UNSIGNED, 1, [Define if wchar_t is unsigned]) ], [
dnl   #ifdef HAVE_WCHAR_H
dnl   #include <wchar.h>
dnl   #endif
dnl   ])
dnl
dnl @version 1.1
dnl @author Ville Laurikari <vl@iki.fi>
AC_DEFUN([AX_CHECK_SIGN], [
 typename=`echo $1 | sed "s/@<:@^a-zA-Z0-9_@:>@/_/g"`
 AC_CACHE_CHECK([whether $1 is signed], ax_cv_decl_${typename}_signed, [
   AC_COMPILE_IFELSE(
     [ AC_LANG_PROGRAM([$4],
         [ int foo @<:@ 1 - 2 * !((($1) -1) < 0) @:>@ ])],
     [ eval "ax_cv_decl_${typename}_signed=\"yes\"" ],
     [ eval "ax_cv_decl_${typename}_signed=\"no\"" ])])
 symbolname=`echo $1 | sed "s/@<:@^a-zA-Z0-9_@:>@/_/g" | tr "@<:@a-z@:>@" "@<:@A-Z@:>@"`
 if eval "test \"\${ax_cv_decl_${typename}_signed}\" = \"yes\""; then
   true
   $2
 elif eval "test \"\${ax_cv_decl_${typename}_signed}\" = \"no\""; then
   true
   $3
 fi
])dnl
