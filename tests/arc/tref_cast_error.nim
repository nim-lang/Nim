discard """
  cmd: "nim c --gc:arc $file"
  errormsg: "expression cannot be cast to ref RootObj"
  joinable: false
"""

type Variant* = object
    refval: ref RootObj

proc newVariant*[T](val: T): Variant =
    let pt = T.new()
    pt[] = val
    result = Variant(refval: cast[ref RootObj](pt))

var v = newVariant(@[1, 2, 3])
