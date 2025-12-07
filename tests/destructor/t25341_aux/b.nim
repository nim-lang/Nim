import ./module

var globalObj: Distinct2[4]

proc b*() =
  globalObj = make1[4]().make2()
