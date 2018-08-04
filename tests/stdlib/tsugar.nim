discard """
  file: "tsugar.nim"
  output: ""
"""
import sugar

block distinctBase:
  type
    Foo[T] = distinct seq[T]
  var a: Foo[int]
  doAssert a.type.distinctBase is seq[int]
