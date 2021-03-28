discard """
  cmd: "nim $target $options $file"
  output: "Hello"
  ccodecheck: "\\i@'a = ((NimStringDesc*) NIM_NIL)'"
"""

proc main() =
  var a = "Hello"
  echo a
  a = ""
  doAssert a.len == 0

main()
