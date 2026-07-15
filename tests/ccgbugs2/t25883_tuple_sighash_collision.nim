discard """
targets: "c cpp"
output: "13"
"""

# bug #25883: C codegen assigns same type hash to tuples with different nesting
# but identical flattened content.
# ((Int[1], Int[2]), Int[13], Int[14]) and ((Int[1], Int[2], Int[13]), Int[14])
# must get distinct C type names.

type
  Int[V: static int] = object

proc main() =
  var b = ((1, 2), 13, 14)
  var c = ((1, 2, 13), 14)
  echo c[0][2]

main()

block:
  type
    Int[V: static int] = object
    Layout[Sh, St] = object
      shape: Sh
      stride: St
  
  func makeB(): auto =
    Layout[((Int[2], Int[3]), Int[5], Int[7]), ((Int[1], Int[2]), Int[6], Int[30])](
      shape: ((Int[2](), Int[3]()), Int[5](), Int[7]()),
      stride: ((Int[1](), Int[2]()), Int[6](), Int[30]())
    )
  
  func makeC(): auto =
    Layout[((Int[2], Int[3], Int[5]), Int[7]), ((Int[1], Int[2], Int[6]), Int[30])](
      shape: ((Int[2](), Int[3](), Int[5]()), Int[7]()),
      stride: ((Int[1](), Int[2](), Int[6]()), Int[30]())
    )
  
  
  proc main() =
    let b = makeB()
    let c = makeC()
  
  main()
