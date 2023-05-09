discard """
  cmd: "nim c --mm:refc $file"
  action: "compile"
"""

template foo(x: typed) =
  discard x

foo:
  var x = "hello"
  x.shallowCopy("test")
  true
