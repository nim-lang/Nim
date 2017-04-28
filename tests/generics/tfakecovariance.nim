template accept(x) =
  static: assert(compiles(x))

template reject(x) =
  static: assert(not compiles(x))

type
  BaseObj = object of RootObj
  DerivedObj = object of BaseObj
  NonDerivedObj = object

  Container[T] = object

var base: BaseObj
var derived: DerivedObj
var nonDerived: NonDerivedObj

var baseContainer: Container[BaseObj]
var derivedContainer: Container[DerivedObj]
var nonDerivedContainer: Container[NonDerivedObj]

# We can fake covariance by listing some specific derived types that
# will be allowed with our overload. This is not a real covariance,
# because there will be multiple instantiations of the proc, but for
# many purposes, it will suffice:

proc wantsSpecificContainers(c: Container[BaseObj or DerivedObj]) = discard

accept wantsSpecificContainers(baseContainer)
accept wantsSpecificContainers(derivedContainer)

reject wantsSpecificContainers(nonDerivedContainer)
reject wantsSpecificContainers(derived)

# Now, let's make a more general solution able to catch all derived types:

type
  DerivedFrom[T] = concept type A
    var derived: ref A
    var base: ref T = derived

proc wantsDerived(x: DerivedFrom[BaseObj]) = discard

accept wantsDerived(base)
accept wantsDerived(derived)

reject wantsDerived(nonDerived)
reject wantsDerived(baseContainer)

proc wantsDerivedContainer(c: Container[DerivedFrom[BaseObj]]) = discard

accept wantsDerivedContainer(baseContainer)
accept wantsDerivedContainer(derivedContainer)

reject wantsDerivedContainer(nonDerivedContainer)

