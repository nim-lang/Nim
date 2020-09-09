discard """
  disabled: "true"
"""

# TODO most tests skip for now

import tables

{.experimental: "strictNotNil".}

type
  Nilable* = ref object
    a*: int
    field*: Nilable
    
  NonNilable* = Nilable not nil

  Nilable2* = nil NonNilable

# Nilable tests

# test deref
proc testDeref(a: Nilable) =
  echo a.a > 0 # can't deref a: it might be nil  

# test and
proc testAnd(a: Nilable) =
  echo not a.isNil and a.a > 0 # ok

# test if else
proc testIfElse(a: Nilable) =
  if a.isNil:
    echo a.a # can't deref a: it is nil
  else:
    echo a.a # ok

# test assign in branch and unifiying that with the main block after end of branch
proc testAssignUnify(a: Nilable, b: int) =
  var a2 = a
  if b == 0:
    a2 = Nilable()
  echo a2.a # can't deref a2: it might be nil

# test else branch and inferring not isNil
proc testElse(a: Nilable, b: int) =
  if a.isNil:
    echo 0
  else:
    echo a.a

# test that here we can infer that n can't be nil anymore
proc testNotNilAfterAssign(a: Nilable, b: int) =
  var n = a
  if n.isNil:
    n = Nilable()
  echo n.a # ok

# test loop
proc testForLoop(a: Nilable) =
  var b = Nilable()
  for i in 0 .. 5:
    echo b.a # can't deref b: it might be nil
    if i == 2:
      b = a
  echo b.a # can't defer b: it might be nil

proc testNonNilDeref(a: NonNilable) =
  echo a.a # ok

proc testFieldCheck(a: Nilable) =
  if not a.isNil and not a.field.isNil:
    echo a.field.a # ok

# not only calls: we can use partitions for dependencies for field aliases
# so we can detect on change what does this affect or was this mutated between us and the original field

proc testRootAliasField(a: Nilable) =
  var aliasA = a
  if not a.isNil and not a.field.isNil:
    aliasA.field = nil
    a.field = nil
    echo a.field.a # can't deref a.field: it might be nil

proc testUniqueHashTree(a: Nilable): Nilable =
  # TODO what would be a clash
  if not a.isNil:
    result = a
  result = Nilable()
  
proc testSeparateShadowingResult(a: Nilable): Nilable =
  result = Nilable()
  if not a.isNil:
    var result: Nilable = nil
  echo result.a


proc testCStringDeref(a: cstring) =
  echo a[0] # can't deref a: it might be nil

proc testNonNilCString(a: cstring not nil) =
  echo a[0] # ok

proc testNilablePtr(a: ptr int) =
  if not a.isNil:
    echo a[] # ok
  echo a[] # can't deref a: it might be nil

proc testNonNilPtr(a: ptr int not nil) =
  echo a[] # ok

# a -> Safe
# a.field -> Safe
# aliasA -> Safe
# aliasA.field -> Nil
# aliasA = a => aliased dependency
# so now aliasA.field -> update dependencies:
# aliasA.field.* : none
# aliasA.field aliases : none
# aliasA aliases : a
# a.field -> Nil

# var globalA = Nilable()

# proc test10(a: Nilable) =
#   if not a.isNil and not a.b.isNil:
#     c_memset(globalA.addr, 0, globalA.sizeOf.csize_t)
#     globalA = nil
#     echo a.a # can't deref a: it might be nil

var nilable: Nilable
var withField = Nilable(a: 0, field: Nilable())
# testRootAliasField(withField)
discard testUniqueHashTree(withField)
# test1(nilable)
# test10(globalA)
