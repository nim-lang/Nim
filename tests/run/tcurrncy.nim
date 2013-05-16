discard """
  file: "tcurrncy.nim"
  output: "25"
"""
template Additive(typ: typeDesc): stmt =
  proc `+` *(x, y: typ): typ {.borrow.}
  proc `-` *(x, y: typ): typ {.borrow.}
  
  # unary operators:
  proc `+` *(x: typ): typ {.borrow.}
  proc `-` *(x: typ): typ {.borrow.}

template Multiplicative(typ, base: typeDesc): stmt {.immediate.} =
  proc `*` *(x: typ, y: base): typ {.borrow.}
  proc `*` *(x: base, y: typ): typ {.borrow.}
  proc `div` *(x: typ, y: base): typ {.borrow.}
  proc `mod` *(x: typ, y: base): typ {.borrow.}

template Comparable(typ: typeDesc): stmt =
  proc `<` * (x, y: typ): bool {.borrow.}
  proc `<=` * (x, y: typ): bool {.borrow.}
  proc `==` * (x, y: typ): bool {.borrow.}

template DefineCurrency(typ, base: expr): stmt {.immediate.} =
  type
    typ* = distinct base
  Additive(typ)
  Multiplicative(typ, base)
  Comparable(typ)
  
  proc `$` * (t: typ): string {.borrow.}

DefineCurrency(TDollar, int)
DefineCurrency(TEuro, int)
echo($( 12.TDollar + 13.TDollar )) #OUT 25



