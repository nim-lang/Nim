discard """
  output: "10\n20"
"""

type
  FonConcept = concept x
    x.x is int

  Implementation = object
    x: int

  Closure = object
    f: proc()

proc f1(x: FonConcept): Closure =
  result.f = proc () =
    echo x.x

proc f2(x: FonConcept): Closure =
  result.f = proc () =
    echo x.x

let x = Implementation(x: 10)
let y = Implementation(x: 20)

let a = x.f1
let b = x.f2
let c = x.f1
let d = y.f2

a.f()
d.f()

