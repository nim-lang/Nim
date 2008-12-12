dnl Like AC_CHECK_FUNCS, but allows the function definition to be
dnl a macro.  This allows for detection of functions which are renamed
dnl with macros to something other than the name we are testing with.
AC_DEFUN([AX_CHECK_FUNCS_COMP],[
  dnl This is magic to make autoheader pick up the config.h.in templates
  dnl automatically.  This uses macros which are probably not public
  dnl (not documented anyway) but this works at least with Automake 2.59.
  AC_FOREACH([AX_Func], [$1],
    [AH_TEMPLATE(AS_TR_CPP(HAVE_[]AX_Func),
                 [Define to 1 if you have the `]AX_Func[' function or macro.])])dnl
  for ax_func in $1; do
    ax_fname=`echo $ax_func | sed "s/@<:@^a-zA-Z0-9_@:>@/_/g"`
    ax_symbolname=`echo $ax_func | sed "s/@<:@^a-zA-Z0-9_@:>@/_/g" | tr "@<:@a-z@:>@" "@<:@A-Z@:>@"`
    AC_CACHE_CHECK([for $ax_func], ax_cv_func_${ax_fname}, [
      AC_LINK_IFELSE(
        [ AC_LANG_PROGRAM(
            [$4
void *foo = $ax_func;
],
            [  return foo != $ax_func; ])],
	[ eval "ax_cv_func_${ax_fname}=\"yes\"" ],
	[ eval "ax_cv_func_${ax_fname}=\"no\"" ])])
    if eval "test \"\${ax_cv_func_${ax_fname}}\" = \"yes\""; then
      AC_DEFINE_UNQUOTED(HAVE_${ax_symbolname}, 1,
        [Define to 1 if you have the $ax_func() function.])
      $2
    else
      true
      $3
    fi
  done
])dnl
