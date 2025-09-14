discard """
  action: compile
"""

# issue #15637

template foo(x: typed) =
  x
  x

template bar(x, y, z: typed) =
  x
  block:
    y
    z
  proc barInner =
    x

  y

  if true:
    z

template hasTypeof(x: typed) =
  discard x
  discard typeof(x)(1)

template hasCastTypeof(x: typed) =
  discard x
  discard cast[typeof(x)](1)

proc test =
  foo:
    block:
      var a = 0

  foo:
    if true:
      let a = 1

  foo:
    block:
      var a = 0
      if true:
        var a = 0

  bar:
    var a = 1
  do:
    var b = 1
  do:
    const c = 1

  block:
    hasTypeof((var a = 0; a))

  block:
    hasCastTypeof((var a = 0; a))

test()
