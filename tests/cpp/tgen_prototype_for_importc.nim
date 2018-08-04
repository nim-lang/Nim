discard """
  targets: "cpp"
  output: '''Hello world'''
"""

# bug #5136

{.compile: "foo.c".}
proc myFunc(): cstring {.importc.}
echo myFunc()
