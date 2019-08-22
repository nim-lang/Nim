discard """
  exitcode: 0
  disabled: '''true'''
"""
import moverloading_typedesc
import tables

type
  LFoo = object
  LBar = object


when true:
  doAssert FBar.new() == 3

  proc new(_: typedesc[LFoo]): int = 0
  proc new[T](_: typedesc[T]): int = 1
  proc new*(_: typedesc[seq[Table[int, seq[Table[int, typedesc]]]]]): int = 7

  doAssert LFoo.new() == 0     # Tests selecting more precise type
  doAssert LBar.new() == 1     # Tests preferring function from local scope
  doAssert FBar.new() == 1
  doAssert FFoo.new() == 2     # Tests selecting more precise type from other module
  doAssert seq[Table[int, seq[Table[int, string]]]].new() == 5     # Truly complex type test
