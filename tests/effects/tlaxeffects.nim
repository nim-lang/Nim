discard """
  cmd: "nim $target $options --legacy:laxEffects $file"
"""


type
  Foo = object
    bar: seq[Foo]

proc `==`(a, b: Foo): bool =
  a.bar == b.bar
