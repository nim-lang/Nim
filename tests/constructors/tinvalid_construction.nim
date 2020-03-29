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

  TRefObjNotNil = TRefObj not nil

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

  PartialRequiresInitRef = ref PartialRequiresInit

  FullRequiresInit {.requiresInit.} = object
    a: int
    b: int

  FullRequiresInitRef = ref FullRequiresInit

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
  (ref THasNotNils)(a: TRefObj(x: 10),
                    b: TRefObj(x: 20))

proc userDefinedDefault(T: typedesc): T =
  # We'll use that to make sure the user cannot cheat
  # with constructing requiresInit types
  discard

proc genericDefault(T: typedesc): T =
  result = default(T)

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
reject default(THasNotNils)
reject userDefinedDefault(THasNotNils)

reject default(TRefObjNotNil)
reject userDefinedDefault(TRefObjNotNil)
reject genericDefault(TRefObjNotNil)

# missing not nils in base
reject TBaseHasNotNils()
reject default(TBaseHasNotNils)
reject userDefinedDefault(TBaseHasNotNils)
reject genericDefault(TBaseHasNotNils)

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
accept PartialRequiresInitRef(a: 10, b: "x")
accept PartialRequiresInitRef(a: 20)
reject PartialRequiresInitRef(b: "x")
reject PartialRequiresInitRef()
accept((ref PartialRequiresInit)(a: 10, b: "x"))
accept((ref PartialRequiresInit)(a: 20))
reject((ref PartialRequiresInit)(b: "x"))
reject((ref PartialRequiresInit)())

reject default(PartialRequiresInit)
reject userDefinedDefault(PartialRequiresInit)
reject:
  var obj: PartialRequiresInit

accept FullRequiresInit(a: 10, b: 20)
reject FullRequiresInit(a: 10)
reject FullRequiresInit(b: 20)
reject FullRequiresInit()
accept FullRequiresInitRef(a: 10, b: 20)
reject FullRequiresInitRef(a: 10)
reject FullRequiresInitRef(b: 20)
reject FullRequiresInitRef()
accept((ref FullRequiresInit)(a: 10, b: 20))
reject((ref FullRequiresInit)(a: 10))
reject((ref FullRequiresInit)(b: 20))
reject((ref FullRequiresInit)())

reject default(FullRequiresInit)
reject userDefinedDefault(FullRequiresInit)
reject:
  var obj: FullRequiresInit

accept FullRequiresInitWithParent(a: notNilRef, b: notNilRef, c: notNilRef, e: 10, d: 20)
accept FullRequiresInitWithParent(a: notNilRef, b: notNilRef, c: nil, e: 10, d: 20)
reject FullRequiresInitWithParent(a: notNilRef, b: nil, c: nil, e: 10, d: 20) # b should not be nil
reject FullRequiresInitWithParent(a: notNilRef, b: notNilRef, e: 10, d: 20)   # c should not be missing
reject FullRequiresInitWithParent(a: notNilRef, b: notNilRef, c: nil, e: 10)  # d should not be missing
reject FullRequiresInitWithParent()
reject default(FullRequiresInitWithParent)
reject userDefinedDefault(FullRequiresInitWithParent)
reject:
  var obj: FullRequiresInitWithParent

# this will be accepted, because the false outer branch will be taken and the inner A branch
accept TNestedChoices()
accept default(TNestedChoices)
accept:
  var obj: TNestedChoices

reject:
  # This proc is illegal, because it tries to produce
  # a default object of a type that requires initialization:
  proc defaultHasNotNils: THasNotNils =
    discard

reject:
  # You cannot cheat by using the result variable to specify
  # only some of the fields
  proc invalidPartialTHasNotNils: THasNotNils =
    result.c = nilRef

reject:
  # The same applies for requiresInit types
  proc invalidPartialRequiersInit: PartialRequiresInit =
    result.b = "x"

# All code paths must return a value when the result requires initialization:
reject:
  proc ifWithoutAnElse: THasNotNils =
    if stdin.readLine == "":
      return THasNotNils(a: notNilRef, b: notNilRef, c: nilRef)

accept:
  # All code paths must return a value when the result requires initialization:
  proc wellFormedIf: THasNotNils =
    if stdin.readLine == "":
      return THasNotNils(a: notNilRef, b: notNilRef, c: nilRef)
    else:
      return THasNotNIls(a: notNilRef, b: notNilRef)

reject:
  proc caseWithoutAllCasesCovered: FullRequiresInit =
    # Please note that these is no else branch here:
    case stdin.readLine
    of "x":
      return FullRequiresInit(a: 10, b: 20)
    of "y":
      return FullRequiresInit(a: 30, b: 40)

accept:
  proc wellFormedCase: FullRequiresInit =
    case stdin.readLine
    of "x":
      result = FullRequiresInit(a: 10, b: 20)
    else:
      # Mixing result and return is fine:
      return FullRequiresInit(a: 30, b: 40)

# but if we supply a run-time value for the inner branch, the compiler won't be able to prove
# that the notnil field was initialized
reject TNestedChoices(outerChoice: false, innerChoice: x) # XXX: The error message is not very good here
reject TNestedChoices(outerChoice: true,  innerChoice: A) # XXX: The error message is not very good here

accept TNestedChoices(outerChoice: false, innerChoice: B)

reject TNestedChoices(outerChoice: false, innerChoice: C)
accept TNestedChoices(outerChoice: false, innerChoice: C, notnil: notNilRef)
reject TNestedChoices(outerChoice: false, innerChoice: C, notnil: nil)

