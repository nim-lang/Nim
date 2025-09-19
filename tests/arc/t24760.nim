discard """
  matrix: "--mm:orc"
  errormsg: "=dup' is not available for type <B>, which is inferred from unavailable '=copy'; requires a copy because it's not the last read of 'b'; another read is done here: t24760.nim(19, 8); routine: g"
"""

type
  A {.inheritable.} = object
  B = object of A

proc `=copy`(a: var A, x: A) {.error.}
#proc `=copy`(a: var B, x: B) {.error.}

proc ffff(v: sink B) =
  echo v

proc g() =
  var b: B
  ffff(b)
  ffff(b)
g()