discard """
cmd: "nim check $file"
action: "reject"
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

proc testFieldNilCheck(a: Nilable) =
  if not a.field.isNil: #[tt.Warning
         ^ can't deref a, it might be nil
  ]#
    echo 0


# test deref
proc testDeref(a: Nilable) =
  echo a.a > 0 #[tt.Warning
       ^ can't deref a, it might be nil
  ]#


# # test and
proc testAnd(a: Nilable) =
  echo not a.isNil and a.a > 0 # ok

# # test if else
proc testIfElse(a: Nilable) =
  if a.isNil:
    echo a.a #[tt.Warning
         ^ can't deref a, it is nil
    ]#
  else:
    echo a.a # ok

proc testAssignUnify(a: Nilable, b: int) =
  var a2 = a
  if b == 0:
    a2 = Nilable()
  echo a2.a #[tt.Warning
       ^ can't deref a2, it might be nil
  ]#

# TODO ok this fails: fix the unifying logic
# # test assign in branch and unifiying that with the main block after end of branch
proc testAssignUnifyNil(a: Nilable, b: int) =
  var a2 = a
  if b == 0:
    a2 = nil
  echo a2.a #[tt.Warning
       ^ can't deref a2, it might be nil
  ]#

# # test else branch and inferring not isNil
# proc testElse(a: Nilable, b: int) =
#   if a.isNil:
#     echo 0
#   else:
#     echo a.a

# # test that here we can infer that n can't be nil anymore
# proc testNotNilAfterAssign(a: Nilable, b: int) =
#   var n = a
#   if n.isNil:
#     n = Nilable()
#   echo n.a # ok

# # test loop
# proc testForLoop(a: Nilable) =
#   var b = Nilable()
#   for i in 0 .. 5:
#     echo b.a # can't deref b: it might be nil
#     if i == 2:
#       b = a
#   echo b.a # can't defer b: it might be nil

# proc testNonNilDeref(a: NonNilable) =
#   echo a.a # ok

# proc testFieldCheck(a: Nilable) =
#   if not a.isNil and not a.field.isNil:
#     echo a.field.a # ok

# # not only calls: we can use partitions for dependencies for field aliases
# # so we can detect on change what does this affect or was this mutated between us and the original field

# TODO when dot expr support is there

# proc testRootAliasField(a: Nilable) =
#   var aliasA = a
#   if not a.isNil and not a.field.isNil:
#     aliasA.field = nil
#     # a.field = nil
#     # aliasA = nil 
#     echo a.field.a # [tt.Warning
#          ^ can't deref a.field, it might be nil
#     ]#

proc callVar(a: var Nilable) =
  a = nil

proc testVarAlias(a: Nilable) =
  var aliasA = a
  if not a.isNil:
    callVar(aliasA)
    echo a.a #[tt.Warning
         ^ can't deref a, it might be nil
    ]#

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

# var it = root;
# while it != nil:
#   baz(it)
#   it = it.next
  # quite different from:
  # it = it.next.next

# # ok, but most calls maybe can raise
# # so this makes us mostly force initialization of result with a valid default

# # a -> Safe
# # a.field -> Safe
# # aliasA -> Safe
# # aliasA.field -> Nil
# # aliasA = a => aliased dependency
# # so now aliasA.field -> update dependencies:
# # aliasA.field.* : none
# # aliasA.field aliases : none
# # aliasA aliases : a
# # a.field -> Nil

# # var globalA = Nilable()

# # proc test10(a: Nilable) =
# #   if not a.isNil and not a.b.isNil:
# #     c_memset(globalA.addr, 0, globalA.sizeOf.csize_t)
# #     globalA = nil
# #     echo a.a # can't deref a: it might be nil

var nilable: Nilable
var withField = Nilable(a: 0, field: Nilable())
# testRootAliasField(withField)
# discard testUniqueHashTree(withField)
# # test1(nilable)
# # test10(globalA)




# # 2
# # "t"
# # [2]

# # a -> 2

# # Node
# #   -> parent

# # Node:
# #   age: int
# #   parent: -> Node

# # -> Node 

# # Node
# # nil

# # parent.age 


# # if not parent.isNil:

# # Root -> 
# #   Child1 ->
# #     Child1_1

# #   Child2 ->
# #     Child2_1


# # Int 

# # Pointer 

# # 2 + 2

# # grandfather.pull(raddish)


# # Grandfather pull Raddish

# # 2 + 2

# # 2 + "e"


