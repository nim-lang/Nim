discard """
  output: "4887 true"
"""

# test the new borrow feature that works with generics:

proc `++`*[T: int | float](a, b: T): T =
  result = a + b
  
type
  DI = distinct int
  DF = distinct float
  DS = distinct string
  
proc `++`(x, y: DI): DI {.borrow.}
proc `++`(x, y: DF): DF {.borrow.}

proc `$`(x: DI): string {.borrow.}
proc `$`(x: DF): string {.borrow.}

echo  4544.DI ++ 343.di, " ", (4.5.df ++ 0.5.df).float == 5.0
