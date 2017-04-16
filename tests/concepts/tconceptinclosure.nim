discard """
  output: '''
10
20
int
20
3
'''
"""

import typetraits

type
  FonConcept = concept x
    x.x is int

  GenericConcept[T] = concept x
    x.x is T
    const L = T.name.len

  Implementation = object
    x: int

  Closure = object
    f: proc()

proc f1(x: FonConcept): Closure =
  result.f = proc () =
    echo x.x

proc f2(x: GenericConcept): Closure =
  result.f = proc () =
    echo x.x
    echo GenericConcept.T.name

proc f3[T](x: GenericConcept[T]): Closure =
  result.f = proc () =
    echo x.x
    echo x.L

let x = Implementation(x: 10)
let y = Implementation(x: 20)

let a = x.f1
let b = x.f2
let c = x.f1
let d = y.f2
let e = y.f3

a.f()
d.f()
e.f()

