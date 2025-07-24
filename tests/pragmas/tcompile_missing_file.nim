discard """
  joinable: false
  errormsg: "cannot find: noexist.c"
"""
{.compile: "noexist.c".}
