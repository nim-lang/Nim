discard """
  matrix: "--mm:orc --undef:nimPreviewNonVarDestructor"
  output: "hello"
"""

# bug #26134

type MyObject = object

proc `=destroy`(v: var MyObject) =
  echo "hello"

proc remove(v: var seq[MyObject]) =
  v.del(0)

proc aaa(v: var seq[MyObject], i: sink MyObject) =
  v.add(i)

proc main =
  var v: seq[MyObject]
  v.aaa(MyObject())
  v.remove()

main()
