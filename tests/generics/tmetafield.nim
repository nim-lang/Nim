discard """
  cmd: "nimrod check $# $#"
  msg: "'proc' is not a concrete type"
  msg: "'Foo' is not a concrete type."
  msg: "invalid type: 'TBaseMed'"
"""

type
  Foo[T] = object
    x: T

  TBaseMed =  object
    doSmth: proc
    data: seq[Foo]

var a: TBaseMed

# issue 188
