discard """
  cmd: "nimrod check $# $#"
  errmsg: "'proc' is not a concrete type"
  errmsg: "'Foo' is not a concrete type."
  errmsg: "invalid type: 'TBaseMed'"
"""

type
  Foo[T] = object
    x: T

  TBaseMed =  object
    doSmth: proc
    data: seq[Foo]

var a: TBaseMed

# issue 188
