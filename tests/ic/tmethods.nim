discard """
  cmd: "nim c --incremental:on $file"
  output: '''Base abc'''
"""

type
  Base = ref object of RootObj
    s: string

method m(b: Base) {.base.} =
  echo "Base ", b.s

var c = Base(s: "abc")
m c

#!EDIT!#

discard """
  cmd: "nim c --incremental:on $file"
  output: '''Base abc
Inherited abc'''
"""

type
  Base = ref object of RootObj
    s: string

  Inherited = ref object of Base


method m(b: Base) {.base.} =
  echo "Base ", b.s

method m(i: Inherited) =
  procCall m(Base i)
  echo "Inherited ", i.s

var c = Inherited(s: "abc")
m c

