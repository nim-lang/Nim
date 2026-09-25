discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''aaaeee
["p", "q", "r"]'''
"""

# A `{.shallow.}` destination type must not shortcut the deep copy when the
# source is static data: `genericShallowAssign` would `incRef` the string
# literals, which have no GC header. `genOptAsgnTuple`/`genOptAsgnObject`
# already give `OnStatic` priority over `tfShallow`; `genGenericAsgn` has to
# agree with them.

type
  Obj {.shallow.} = object
    a, b, c, d, e: string      # asgnComplexity > 4, so genGenericAsgn is used
  ShallowArray {.shallow.} = array[3, string]
  Holder = ref object
    o: Obj
    a: ShallowArray

const
  c1 = Obj(a: "aaa", b: "bbb", c: "ccc", d: "ddd", e: "eee")
  ca: ShallowArray = ["p", "q", "r"]

proc main =
  var h = Holder()
  h.o = c1
  h.a = ca
  echo h.o.a, h.o.e
  echo h.a

main()
