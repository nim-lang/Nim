import pkg3

proc foo*() =
  echo "pkg2"
  pkg3.foo()
