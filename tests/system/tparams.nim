discard """
joinable: false
"""

# not joinable because it executes itself with parameters
import os
import osproc
import parseopt
import sequtils

let argv = commandLineParams()

if argv == @[]:
  # this won't work with spaces
  doAssert execShellCmd(getAppFilename() & " \"foo bar\" --aa:bar=a --a=c:d --ab -c --a[baz]:doo") == 0
else:
  let f = toSeq(getopt())
  doAssert f[0].kind == cmdArgument and f[0].key == "foo bar" and f[0].val == ""
  doAssert f[1].kind == cmdLongOption and f[1].key == "aa" and f[1].val == "bar=a"
  doAssert f[2].kind == cmdLongOption and f[2].key == "a" and f[2].val == "c:d"
  doAssert f[3].kind == cmdLongOption and f[3].key == "ab" and f[3].val == ""
  doAssert f[4].kind == cmdShortOption and f[4].key == "c" and f[4].val == ""
