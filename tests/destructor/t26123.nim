discard """
  matrix: "--mm:orc"
  output: "destroy b"
"""

# bug #26123

type
  A = ptr AObj

  AObj = object
    b: B

  B = distinct ptr BObj

  BObj = object
    a: A

proc `=destroy`(r: var B) =
  echo "destroy b"

proc main() =
  var a = create(AObj)
  var b = B(create(BObj))
  a.b = b
  cast[ptr BObj](b).a = a

main()
