discard """
cmd: "nim check --warningAsError:StrictNotNil $file"
action: "compile"
"""

import tables

{.experimental: "strictNotNil".}

type
  Nilable* = ref object
    a*: int
    field*: Nilable
    
  NonNilable* = Nilable not nil

  Nilable2* = nil NonNilable


# proc `[]`(a: Nilable, b: int): Nilable =
#   nil


# Nilable tests



# # test and
proc testAnd(a: Nilable) =
  echo not a.isNil and a.a > 0 # ok


# test else branch and inferring not isNil
# proc testElse(a: Nilable, b: int) =
#   if a.isNil:
#     echo 0
#   else:
#     echo a.a

# test that here we can infer that n can't be nil anymore
proc testNotNilAfterAssign(a: Nilable, b: int) =
  var n = a # 1: MaybeNil 2: Safe
  if n.isNil: # 1: Nil 2: Safe
    n = Nilable() # 1: Safe 2: Safe 
  echo n.a # ok

proc callVar(a: var Nilable) =
   a = nil

proc testVarAlias(a: Nilable) = # a: 0 aliasA: 1 {0} {1} 
  var aliasA = a # {0, 1} 0 MaybeNil 1 MaybeNil
  if not a.isNil: # {0, 1} 0 Safe 1 Safe
    callVar(aliasA) # {0, 1} 0 MaybeNil 1 MaybeNil
    # if aliasA stops being in alias: it might be nil, but then a is still not nil
    # if not: it cant be nil as it still points here
    echo a.a # ok 

proc testAliasCheck(a: Nilable) =
  var aliasA = a
  if not a.isNil:
    echo aliasA.a # ok

# proc testNonNilDeref(a: NonNilable) =
#   echo a.a # ok

# proc testFieldCheck(a: Nilable) =
#   if not a.isNil and not a.field.isNil:
#     echo a.field.a # ok

# # not only calls: we can use partitions for dependencies for field aliases
# # so we can detect on change what does this affect or was this mutated between us and the original field


# proc testUniqueHashTree(a: Nilable): Nilable =
#   # TODO what would be a clash
#   var field = 0
#   if not a.isNil and not a.field.isNil:
#     # echo a.field.a
#     echo a[field].a
#   result = Nilable()
  
# proc testSeparateShadowingResult(a: Nilable): Nilable =
#   result = Nilable()
#   if not a.isNil:
#     var result: Nilable = nil
#   echo result.a


# proc testCStringDeref(a: cstring) =
#   echo a[0] # can't deref a: it might be nil

# proc testNonNilCString(a: cstring not nil) =
#   echo a[0] # ok

# proc testNilablePtr(a: ptr int) =
#   if not a.isNil:
#     echo a[] # ok
#   echo a[] # can't deref a: it might be nil

# proc testNonNilPtr(a: ptr int not nil) =
#   echo a[] # ok

# proc raiseCall: NonNilable = # return value is nil
#   raise newException(ValueError, "raise for test") 

# proc testTryCatch(a: Nilable) =
#   var other = a
#   try:
#     other = raiseCall()
#   except:
#     discard
#   echo other.a # can't deref other: it might be nil

# proc testTryCatchDetectNoRaise(a: Nilable) =
#   var other = Nilable()
#   try:
#     other = nil
#     other = a
#     other = Nilable()
#   except:
#     other = nil
#   echo other.a # ok

# proc testTryCatchDetectFinally =
#   var other = Nilable()
#   try:
#     other = nil
#     other = Nilable()
#   except:
#     other = Nilable()
#   finally:
#     other = nil
#   echo other.a # can't deref other: it is nil

# proc testTryCatchDetectNilableWithRaise(b: bool) =
#   var other = Nilable()
#   try:
#     if b:
#       other = nil
#     else:
#       other = Nilable()
#       var other2 = raiseCall()
#   except:
#     echo other.a # ok

#   echo other.a # can't deref a: it might be nil

# proc testRaise(a: Nilable) =
#   if a.isNil:
#     raise newException(ValueError, "a == nil")
#   echo a.a # ok

# proc testBlockScope(a: Nilable) =
#   var other = a
#   block:
#     var other = Nilable()
#     echo other.a # ok
#   echo other.a # can't deref other: it might be nil

# # (ask Araq about this: not supported yet) ok we can't really get the nil value from here, so should be ok
# proc testDirectRaiseCall: NonNilable =
#   var a = raiseCall()
#   result = NonNilable()

# proc testStmtList =
#   var a = Nilable()
#   block:
#     a = nil
#     a = Nilable()
#   echo a.a # ok

# proc callChange(a: Nilable) =
#   a.field = nil

# proc testCallAlias =
#   var a = Nilable(field: Nilable())
#   callChange(a)
#   echo a.field.a # can't deref a.field, it might be nil

# # proc test10(a: Nilable) =
# #   if not a.isNil and not a.b.isNil:
# #     c_memset(globalA.addr, 0, globalA.sizeOf.csize_t)
# #     globalA = nil
# #     echo a.a # can't deref a: it might be nil

var nilable: Nilable
var withField = Nilable(a: 0, field: Nilable())
