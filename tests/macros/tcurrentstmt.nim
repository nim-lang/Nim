import macros

macro test(st: expr): expr =
  echo st.lispRepr
  echo currentStmt().lispRepr
  st

if test(1) == 1:
  echo test(2) + 2
