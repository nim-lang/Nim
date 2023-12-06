discard """
cmd: "nim check $file"
"""

{.pragma test: foo.} #[tt.Error
^ invalid pragma:  {.pragma, test: foo.} ]#
