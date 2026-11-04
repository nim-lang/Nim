discard """
  matrix: "--mm:orc; --mm:orc -d:danger; --mm:orc --strings:sso; --mm:orc -d:danger --strings:sso"
  exitcode: 1
  outputsub: "fatal error: string or seq size overflows the address space"
"""

# The size computations of the ARC/ORC string implementations must not wrap
# around, otherwise a far too small block is allocated and then written to.
# A short string is used so that `--strings:sso` takes the inline -> heap
# transition, whose capacity computation used to overflow.

proc main =
  var s = "abc"
  s.setLen(high(int))
  s[high(int) - 1] = 'x'
  echo "not reached"

main()
