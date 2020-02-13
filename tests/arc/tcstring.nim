discard """
  cmd: "nim c --gc:arc -r $file"
  nimout: '''hello
h
o
'''
"""

# Issue #13321: [codegen] --gc:arc does not properly emit cstring, results in SIGSEGV

let a = "hello".cstring
echo a
echo a[0]
echo a[4]
doAssert a[a.len] == '\0'

