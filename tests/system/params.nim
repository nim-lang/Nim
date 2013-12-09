import os
import osproc
import parseopt
import sequtils

let argv = commandLineParams()

if argv == @[]:
  # this won't work with spaces
  assert execShellCmd(getAppFilename() & " \"foo bar\" --aa:bar --ab -c --a[baz]:doo") == 0
else:
  let f = toSeq(getopt())
  echo f.repr
  assert f[0].kind == cmdArgument and f[0].key == "foo bar" and f[0].val == ""
  assert f[1].kind == cmdLongOption and f[1].key == "aa" and f[1].val == "bar"
  assert f[2].kind == cmdLongOption and f[2].key == "ab" and f[2].val == ""
  assert f[3].kind == cmdShortOption and f[3].key == "c" and f[3].val == ""
