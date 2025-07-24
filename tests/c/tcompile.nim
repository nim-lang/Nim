discard """
  output: '''44'''
  joinable: "false"
"""

{.compile: "tcompile.c".}

proc foo(a, b: cint): cint {.importc: "foo", cdecl.}

echo foo(40, 4)
