discard """
  cmd: "nim $target $options $file"
  output: "Hello"
  ccodecheck: "\\i@'a = ((NimStringDesc*) NIM_NIL)'"
"""

import std/assertions

proc main() =
  var a = "Hello"
  echo a
  a = ""
  doAssert a.len == 0

main()
