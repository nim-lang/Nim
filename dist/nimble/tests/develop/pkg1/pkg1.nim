import pkg2

proc foo*() =
  echo "pkg1"
  pkg2.foo()
