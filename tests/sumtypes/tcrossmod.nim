discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
(`kind: Some, val: (x: 1)) (`kind: Some, val: (x: 2)) (`kind: Some, val: 3)
1.5 Tree[system.float64] (`kind: None)
(`kind: Some, val: 4) (`kind: None) 5
(`kind: None)(`kind: None)(`kind: Ok, code: 1)
Opt[system.int] Res
false false
'''
"""

# Sum types used across module boundaries.
import msumtypes as m
import msumtypes_clash

type B = object
  x: int

# generic sum types, generic procs and templates of another module:
echo Some(val: B(x: 1)), " ", some(B(x: 2)), " ", mk(3)
let t = leafs(1.5, 2.5)
let o: Opt[B] = None()
echo t.l.v, " ", typeof(t), " ", o

# qualified branch names:
let n: m.Opt[int] = m.None()
echo m.Some(val: 4), " ", n, " ", m.Leaf(v: 5).v

# `None` of two modules, selected by the expected type or a qualifier:
let x: Opt[int] = None()
let y: Res = None()
echo x, y, Ok(code: 1)
echo typeof(Opt[int](m.None())), " ", typeof(msumtypes_clash.None())

# branch names of private types or private fields stay hidden:
echo compiles(PA()), " ", compiles(H1(secret: 1))
