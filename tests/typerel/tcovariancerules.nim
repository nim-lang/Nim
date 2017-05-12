discard """
cmd: "nim check $file"
"""

template accept(x) =
  static: assert(compiles(x))

template reject(x) =
  static: assert(not compiles(x))

type
  Animal = object of TObject
    x: int

  Dog = object of Animal
    y: int

  Cat = object of Animal
    z: int

  AnimalRef = ref Animal
  AnimalPtr = ptr Animal

var dog = new(Dog)
var cat = new(Cat)

proc wantsRefArray(x: array[2, ref Animal]) = discard

accept:
  wantsRefArray([AnimalRef(dog), AnimalRef(dog)])
  wantsRefArray([AnimalRef(cat), AnimalRef(dog)])
  wantsRefArray([AnimalRef(cat), dog])

  # there is a special rule that detects the base
  # type of polymorphic arrays
  wantsRefArray([cat, dog])

reject:
  # But the current lack of covariance kicks in
  # when we try to pass a derived type array
  wantsRefArray([cat, cat])

var animalRefArray: array[2, ref Animal]

accept:
  animalRefArray = [AnimalRef(dog), AnimalRef(dog)]
  animalRefArray = [AnimalRef(cat), dog]

reject:
  animalRefArray = [dog, dog]

accept:
  var animal: AnimalRef = dog
  animal = cat

var vdog: Dog
var vcat: Cat

reject:
  vcat = vdog

# XXX: The next two cases seem incosistent, perhaps we should change the rules
accept:
  # truncating copies are allowed
  var vanimal: Animal = vdog
  vanimal = vdog

reject:
  # truncating copies are not allowed with arrays
  var vanimalArray: array[2, Animal]
  var vdogArray = [vdog, vdog]
  vanimalArray = vdogArray

accept:
  # a more explicit version of a truncating copy that
  # should probably always remain allowed
  var vnextnimal: Animal = Animal(vdog)

proc wantsRefSeq(x: seq[AnimalRef]) = discard

accept:
  wantsRefSeq(@[AnimalRef(dog), AnimalRef(dog)])
  wantsRefSeq(@[AnimalRef(cat), AnimalRef(dog)])
  wantsRefSeq(@[AnimalRef(cat), dog])
  wantsRefSeq(@[cat, dog])

reject:
  wantsRefSeq(@[cat, cat])

var animalRefSeq: seq[ref Animal]

accept:
  animalRefArray = [AnimalRef(dog), AnimalRef(dog)]
  animalRefArray = [AnimalRef(cat), dog]

reject:
  animalRefArray = [dog, dog]

var pdog: ptr Dog
var pcat: ptr Cat

proc wantsPointer(x: ptr Animal) =
  discard

accept:
  wantsPointer pdog
  wantsPointer pcat

# covariance should be disabled when var is involved
proc wantsVarPointer1(x: var ptr Animal) =
  discard

proc wantsVarPointer2(x: var AnimalPtr) =
  discard

reject wantsVarPointer1(pdog)
reject wantsVarPointer2(pcat)

proc usesVarRefSeq(x: var seq[AnimalRef]) = discard
proc usesVarRefArray(x: var array[2, AnimalRef]) = discard

reject:
  var catsSeq = @[cat, cat]
  usesVarRefSeq catsSeq

reject:
  var catsArray = [cat, cat]
  usesVarRefArray catsArray

# covariance may be allowed for certain extern types

{.emit: """
template <class T> struct FN { typedef void (*type)(T); };
template <class T> struct ARR { typedef T type[2]; };
""".}

type
  MyPtr {.importcpp: "'0 *"} [out T] = distinct ptr T
  MySeq {.importcpp: "ARR<'0>::type"} [out T] = object
  MyAction {.importcpp: "FN<'0>::type"} [in T] = object

var
  cAnimal: MyPtr[Animal]
  cDog: MyPtr[Dog]
  cCat: MyPtr[Cat]

  cAnimalFn: MyAction[Animal]
  cCatFn: MyAction[Cat]
  cDogFn: MyAction[Dog]

  cRefAnimalFn: MyAction[ref Animal]
  cRefCatFn: MyAction[ref Cat]
  cRefDogFn: MyAction[ref Dog]

accept:
  cAnimal = cDog
  cAnimal = cCat

  cDogFn = cAnimalFn
  cCatFn = cAnimalFn

  cRefDogFn = cRefAnimalFn
  cRefCatFn = cRefAnimalFn

reject: cDogFn = cRefAnimalFn
reject: cCatFn = cRefAnimalFn

reject: cCat = cDog
reject: cAnimalFn = cDogFn
reject: cAnimalFn = cCatFn
reject: cRefAnimalFn = cRefDogFn
reject: cRefAnimalFn = cRefCatFn
reject: cRefAnimalFn = cDogFn

var
  ptrPtrDog: ptr ptr Dog
  ptrPtrAnimal: ptr ptr Animal

reject: ptrPtrDog = ptrPtrAnimal

type
  RefAlias[T] = ref T

# Try to break the rules by introducing some tricky
# double indirection types:
var
  cPtrRefAnimal: MyPtr[ref Animal]
  cPtrRefDog: MyPtr[ref Dog]

  cPtrAliasRefAnimal: MyPtr[RefAlias[Animal]]
  cPtrAliasRefDog: MyPtr[RefAlias[Dog]]

  cDoublePtrAnimal: MyPtr[MyPtr[Animal]]
  cDoublePtrDog: MyPtr[MyPtr[Dog]]

reject: cPtrRefAnimal = cPtrRefDog
reject: cDoublePtrAnimal = cDoublePtrDog
reject: cRefAliasPtrAnimal = cRefAliasPtrDog
reject: cPtrRefAnimal = cRefAliasPtrDog
reject: cPtrAliasRefAnimal = cPtrRefDog

var
  # Array and Sequence types are covariant only
  # when instantiated with ref or ptr types:
  cAnimals: MySeq[ref Animal]
  cDogs: MySeq[ref Dog]

  # "User-defined" pointer types should be OK too:
  cAnimalPtrSeq: MySeq[MyPtr[Animal]]
  cDogPtrSeq: MySeq[MyPtr[Dog]]

  # Value types shouldn't work:
  cAnimalValues: MySeq[Animal]
  cDogValues: MySeq[Dog]

  # Double pointer types should not work either:
  cAnimalRefPtrSeq: MySeq[ref MyPtr[Animal]]
  cDogRefPtrSeq: MySeq[ref MyPtr[Dog]]
  cAnimalPtrPtrSeq: MySeq[ptr ptr Animal]
  cDogPtrPtrSeq: MySeq[ptr ptr Dog]

accept:
  cAnimals = cDogs
  cAnimalPtrSeq = cDogPtrSeq

reject: cAnimalValues = cDogValues
reject: cAnimalRefPtrSeq = cDogRefPtrSeq
reject: cAnimalPtrPtrSeq = cDogPtrPtrSeq

proc wantsAnimalSeq(x: MySeq[Animal]) = discard
proc wantsAnimalRefSeq(x: MySeq[ref Animal]) = discard
proc modifiesAnimalRefSeq(x: var MySeq[ref Animal]) = discard
proc usesAddressOfAnimalRefSeq(x: ptr MySeq[ref Animal]) = discard

accept wantsAnimalSeq(cAnimalValues)
reject wantsAnimalSeq(cDogValues)
reject wantsAnimalSeq(cAnimals)

reject wantsAnimalRefSeq(cAnimalValues)
reject wantsAnimalRefSeq(cDogValues)
accept wantsAnimalRefSeq(cAnimals)
accept wantsAnimalRefSeq(cDogs)

reject modifiesAnimalRefSeq(cAnimalValues)
reject modifiesAnimalRefSeq(cDogValues)
accept modifiesAnimalRefSeq(cAnimals)
reject modifiesAnimalRefSeq(cDogs)

reject usesAddressOfAnimalRefSeq(addr cAnimalValues)
reject usesAddressOfAnimalRefSeq(addr cDogValues)
accept usesAddressOfAnimalRefSeq(addr cAnimals)
reject usesAddressOfAnimalRefSeq(addr cDogs)

