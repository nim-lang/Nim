import tables

type
  NonNilable* = ref object
    a*: int
    
  Nilable* = nil NonNilable

# Nilable tests

# test deref
proc test1(a: Nilable) =
  echo a.a > 0 # can't deref a: it might be nil  

# test and
proc test2(a: Nilable) =
  echo not a.isNil and a.a > 0 # ok

# test if else
proc test3(a: Nilable) =
  if a.isNil:
    echo a.a # can't deref a: it is nil
  else:
    echo a.a # ok

# test assign in branch and unifiying that with the main block after end of branch
proc test4(a: Nilable, b: int) =
  var a2 = a
  if b == 0:
    a2 = Nilable()
  echo a2.a # can't deref a2: it might be nil

# test else branch and inferring not isNil
proc test5(a: Nilable, b: int) =
  if a.isNil:
    echo 0
  else:
    echo a.a

# test that here we can infer that n can't be nil anymore
proc test6(a: Nilable, b: int) =
  var n = a
  if n.isNil:
    n = Nilable()
  echo n.a # ok

# test loop
proc test7(a: Nilable) =
  var b = Nilable()
  for i in 0 .. 5:
    echo b.a # can't deref b: it might be nil
    if i == 2:
      b = a
  echo b.a # can't defer b: it might be nil

proc test8(a: NonNilable) =
  echo a.a # ok

var nilable: Nilable
# test1(nilable)
