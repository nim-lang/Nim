discard """
  output: "6"
"""

# `--os:standalone` (set in nim.cfg, so it also applies to testament's
# `_temp.nim` copy) makes system.nim `include "$projectpath/panicoverride"`.
# The IC dependency scanner must expand `$projectpath` to see that include;
# otherwise `mstandalonehw` (imported by `panicoverride` and by
# `mstandaloneuser`, and itself importing std/bitops) is not grouped with
# system and the build fails with "symbol has no offset".
import mstandaloneuser

proc printf(frmt: cstring) {.varargs, importc, header: "<stdio.h>", cdecl.}

printf("%d\n", cint(user(6)))
