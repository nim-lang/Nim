template accept(x) =
  static: assert compiles(x)

template reject(x) =
  static: assert(not compiles(x))

{.experimental: "notnil".}

type
  TRefObj = ref object
    x: int

  THasNotNils = object of RootObj
    a: TRefObj not nil
    b: TRefObj not nil
    c: TRefObj

  THasNotNilsRef = ref THasNotNils

  TChoice = enum A, B, C, D, E, F

  TBaseHasNotNils = object of THasNotNils
    case choice: TChoice
    of A:
      moreNotNils: THasNotNils
    of B:
      indirectNotNils: ref THasNotNils
    else:
      discard

  PartialRequiresInit = object
    a {.requiresInit.}: int
    b: string

  FullRequiresInit {.requiresInit.} = object
    a: int
    b: int

  FullRequiresInitWithParent {.requiresInit.} = object of THasNotNils
    e: int
    d: int

  TObj = object
    case choice: TChoice
    of A:
      a: int
    of B, C:
      bc: int
    of D:
      d: TRefObj
    of E:
      e1: TRefObj
      e2: int
    else:
      f: string

  TNestedChoices = object
    case outerChoice: bool
    of true:
      truthy: int
    else:
      case innerChoice: TChoice
      of A:
        a: int
      of B:
        b: int
      else:
        notnil: TRefObj not nil

var x = D
var nilRef: TRefObj
var notNilRef = TRefObj(x: 20)

proc makeHasNotNils: ref THasNotNils =
  result.a = TRefObj(x: 10)
  result.b = TRefObj(x: 20)

accept TObj()
accept TObj(choice: A)
reject TObj(choice: A, bc: 10)  # bc is in the wrong branch
accept TObj(choice: B, bc: 20)
reject TObj(a: 10)              # branch selected without providing discriminator
reject TObj(choice: x, a: 10)   # the discrimantor must be a compile-time value when a branch is selected
accept TObj(choice: x)          # it's OK to use run-time value when a branch is not selected
accept TObj(choice: F, f: "")   # match an else clause
reject TObj(f: "")              # the discriminator must still be provided for an else clause
reject TObj(a: 10, f: "")       # conflicting fields
accept TObj(choice: E, e1: TRefObj(x: 10), e2: 10)

accept THasNotNils(a: notNilRef, b: notNilRef, c: nilRef)
# XXX: the "not nil" logic in the compiler is not strong enough to catch this one yet:
# reject THasNotNils(a: notNilRef, b: nilRef, c: nilRef)
reject THasNotNils(b: notNilRef, c: notNilRef)              # there is a missing not nil field
reject THasNotNils()                                        # again, missing fields
accept THasNotNils(a: notNilRef, b: notNilRef)              # it's OK to omit a non-mandatory field

# missing not nils in base
reject TBaseHasNotNils()

# once you take care of them, it's ok
accept TBaseHasNotNils(a: notNilRef, b: notNilRef, choice: D)

# this one is tricky!
# it has to be rejected, because choice gets value A by default (0) and this means
# that the THasNotNils field will be active (and it will demand more initialized fields).
reject TBaseHasNotNils(a: notNilRef, b: notNilRef)

# you can select a branch without mandatory fields
accept TBaseHasNotNils(a: notNilRef, b: notNilRef, choice: B)
accept TBaseHasNotNils(a: notNilRef, b: notNilRef, choice: B, indirectNotNils: nil)

# but once you select a branch with mandatory fields, you must specify them
reject TBaseHasNotNils(a: notNilRef, b: notNilRef, choice: A)
reject TBaseHasNotNils(a: notNilRef, b: notNilRef, choice: A, indirectNotNils: nil)
reject TBaseHasNotNils(a: notNilRef, b: notNilRef, choice: A, moreNotNils: THasNotNils())
accept TBaseHasNotNils(a: notNilRef, b: notNilRef, choice: A, moreNotNils: THasNotNils(a: notNilRef, b: notNilRef))

# all rules apply to sub-objects as well
accept TBaseHasNotNils(a: notNilRef, b: notNilRef, choice: B, indirectNotNils: makeHasNotNils())
reject TBaseHasNotNils(a: notNilRef, b: notNilRef, choice: B, indirectNotNils: THasNotNilsRef())
accept TBaseHasNotNils(a: notNilRef, b: notNilRef, choice: B, indirectNotNils: THasNotNilsRef(a: notNilRef, b: notNilRef))

# Accept only instances where the `a` field is present
accept PartialRequiresInit(a: 10, b: "x")
accept PartialRequiresInit(a: 20)
reject PartialRequiresInit(b: "x")
reject PartialRequiresInit()

accept FullRequiresInit(a: 10, b: 20)
reject FullRequiresInit(a: 10)
reject FullRequiresInit(b: 20)

accept FullRequiresInitWithParent(a: notNilRef, b: notNilRef, c: notNilRef, e: 10, d: 20)
accept FullRequiresInitWithParent(a: notNilRef, b: notNilRef, c: nil, e: 10, d: 20)
reject FullRequiresInitWithParent(a: notNilRef, b: nil, c: nil, e: 10, d: 20) # b should not be nil
reject FullRequiresInitWithParent(a: notNilRef, b: notNilRef, e: 10, d: 20)   # c should not be missing
reject FullRequiresInitWithParent(a: notNilRef, b: notNilRef, c: nil, e: 10)  # d should not be missing
reject FullRequiresInitWithParent()

# this will be accepted, because the false outer branch will be taken and the inner A branch
accept TNestedChoices()

# but if we supply a run-time value for the inner branch, the compiler won't be able to prove
# that the notnil field was initialized
reject TNestedChoices(outerChoice: false, innerChoice: x) # XXX: The error message is not very good here
reject TNestedChoices(outerChoice: true,  innerChoice: A) # XXX: The error message is not very good here

accept TNestedChoices(outerChoice: false, innerChoice: B)

reject TNestedChoices(outerChoice: false, innerChoice: C)
accept TNestedChoices(outerChoice: false, innerChoice: C, notnil: notNilRef)
reject TNestedChoices(outerChoice: false, innerChoice: C, notnil: nil)

