discard """
  cmd: "nim cpp $file"
  output: '''Hello world'''
"""

# bug #5136

{.compile: "foo.c".}
proc myFunc(): cstring {.importc.}
echo myFunc()
