discard """
  cmd: "nimrod check $options $file"
  errormsg: "'proc' is not a concrete type"
  errormsg: "'Foo' is not a concrete type."
  errormsg: "invalid type: 'TBaseMed'"
"""

type
  Foo[T] = object
    x: T

  TBaseMed =  object
    doSmth: proc
    data: seq[Foo]

var a: TBaseMed

# issue 188
