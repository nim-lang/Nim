type
  BaseObject*[N: static int] = object
    value*: int

  Distinct1*[N: static int] = distinct BaseObject[N]
  Distinct2*[N: static int] = distinct BaseObject[N]

proc `=copy`*[N: static int](dest: var Distinct2[N], src: Distinct2[N]) {.error: "no".}

proc make1*[N: static int](): Distinct1[N] =
  Distinct1[N](BaseObject[N](value: 0))

proc make2*[N: static int](u: sink Distinct1[N]): Distinct2[N] =
  Distinct2[N](BaseObject[N](u))
