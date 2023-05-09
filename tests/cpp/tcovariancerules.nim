discard """
targets: "cpp"
output: '''
cat
cat
dog
dog
cat
cat
dog
dog X
cat
cat
dog
dog
dog
dog
dog 1
dog 2
'''
"""

template accept(x) =
  static: assert(compiles(x))

template reject(x) =
  static: assert(not compiles(x))

import macros

macro skipElse(n: untyped): untyped = n[0]

template acceptWithCovariance(x, otherwise): untyped =
  when defined nimEnableCovariance:
    x
  else:
    reject(x)
    skipElse(otherwise)

type
  Animal = object of RootObj
    x: string

  Dog = object of Animal
    y: int

  Cat = object of Animal
    z: int

  AnimalRef = ref Animal
  AnimalPtr = ptr Animal

  RefAlias[T] = ref T

var dog = new(Dog)
dog.x = "dog"

var cat = new(Cat)
cat.x = "cat"

proc makeDerivedRef(x: string): ref Dog =
  new(result)
  result.x = x

proc makeDerived(x: string): Dog =
  result.x = x

var covariantSeq = @[makeDerivedRef("dog 1"), makeDerivedRef("dog 2")]
var nonCovariantSeq = @[makeDerived("dog 1"), makeDerived("dog 2")]
var covariantArr = [makeDerivedRef("dog 1"), makeDerivedRef("dog 2")]
var nonCovariantArr = [makeDerived("dog 1"), makeDerived("dog 2")]

proc wantsCovariantSeq1(s: seq[ref Animal]) =
  for a in s: echo a.x

proc wantsCovariantSeq2(s: seq[AnimalRef]) =
  for a in s: echo a.x

proc wantsCovariantSeq3(s: seq[RefAlias[Animal]]) =
  for a in s: echo a.x

proc wantsCovariantOpenArray(s: openArray[ref Animal]) =
  for a in s: echo a.x

proc modifiesCovariantOpenArray(s: var openArray[ref Animal]) =
  for a in s: echo a.x

proc modifiesDerivedOpenArray(s: var openArray[ref Dog]) =
  for a in s: echo a.x

proc wantsNonCovariantOpenArray(s: openArray[Animal]) =
  for a in s: echo a.x

proc wantsCovariantArray(s: array[2, ref Animal]) =
  for a in s: echo a.x

proc wantsNonCovariantSeq(s: seq[Animal]) =
  for a in s: echo a.x

proc wantsNonCovariantArray(s: array[2, Animal]) =
  for a in s: echo a.x

proc modifiesCovariantSeq(s: var seq[ref Animal]) =
  for a in s: echo a.x

proc modifiesCovariantArray(s: var array[2, ref Animal]) =
  for a in s: echo a.x

proc modifiesCovariantSeq(s: ptr seq[ref Animal]) =
  for a in s[]: echo a.x

proc modifiesCovariantArray(s: ptr array[2, ref Animal]) =
  for a in s[]: echo a.x

proc modifiesDerivedSeq(s: var seq[ref Dog]) =
  for a in s: echo a.x

proc modifiesDerivedArray(s: var array[2, ref Dog]) =
  for a in s: echo a.x

proc modifiesDerivedSeq(s: ptr seq[ref Dog]) =
  for a in s[]: echo a.x

proc modifiesDerivedArray(s: ptr array[2, ref Dog]) =
  for a in s[]: echo a.x

accept:
  wantsCovariantArray([AnimalRef(dog), AnimalRef(dog)])
  wantsCovariantArray([AnimalRef(cat), AnimalRef(dog)])
  wantsCovariantArray([AnimalRef(cat), dog])

  # there is a special rule that detects the base
  # type of polymorphic arrays
  wantsCovariantArray([cat, dog])

acceptWithCovariance:
  wantsCovariantArray([cat, cat])
else:
  echo "cat"
  echo "cat"

var animalRefArray: array[2, ref Animal]

accept:
  animalRefArray = [AnimalRef(dog), AnimalRef(dog)]
  animalRefArray = [AnimalRef(cat), dog]

acceptWithCovariance:
  animalRefArray = [dog, dog]
  wantsCovariantArray animalRefArray
else:
  echo "dog"
  echo "dog"

accept:
  var animal: AnimalRef = dog
  animal = cat

var vdog: Dog
vdog.x = "dog value"
var vcat: Cat
vcat.x = "cat value"

reject:
  vcat = vdog

# XXX: The next two cases seem inconsistent, perhaps we should change the rules
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
  wantsCovariantSeq1(@[AnimalRef(dog), AnimalRef(dog)])
  wantsCovariantSeq1(@[AnimalRef(cat), AnimalRef(dog)])
  wantsCovariantSeq1(@[AnimalRef(cat), dog])
  wantsCovariantSeq1(@[cat, dog])

  wantsCovariantSeq2(@[AnimalRef(dog), AnimalRef(dog)])
  wantsCovariantSeq2(@[AnimalRef(cat), AnimalRef(dog)])
  wantsCovariantSeq2(@[AnimalRef(cat), dog])
  wantsCovariantSeq2(@[cat, dog])

  wantsCovariantSeq3(@[AnimalRef(dog), AnimalRef(dog)])
  wantsCovariantSeq3(@[AnimalRef(cat), AnimalRef(dog)])
  wantsCovariantSeq3(@[AnimalRef(cat), dog])
  wantsCovariantSeq3(@[cat, dog])

  wantsCovariantOpenArray([cat, dog])

acceptWithCovariance:
  wantsCovariantSeq1(@[cat, cat])
  wantsCovariantSeq2(@[dog, makeDerivedRef("dog X")])
  # XXX: wantsCovariantSeq3(@[cat, cat])

  wantsCovariantOpenArray(@[cat, cat])
  wantsCovariantOpenArray([dog, dog])
else:
  echo "cat"
  echo "cat"
  echo "dog"
  echo "dog X"
  echo "cat"
  echo "cat"
  echo "dog"
  echo "dog"

var dogRefs = @[dog, dog]
var dogRefsArray = [dog, dog]
var animalRefs = @[dog, cat]

accept:
  modifiesDerivedArray(dogRefsArray)
  modifiesDerivedSeq(dogRefs)

reject modifiesCovariantSeqd(ogRefs)
reject modifiesCovariantSeq(addr(dogRefs))
reject modifiesCovariantSeq(dogRefs.addr)

reject modifiesCovariantArray([dog, dog])
reject modifiesCovariantArray(dogRefsArray)
reject modifiesCovariantArray(addr(dogRefsArray))
reject modifiesCovariantArray(dogRefsArray.addr)

var dogValues = @[vdog, vdog]
var dogValuesArray = [vdog, vdog]
when false:
  var animalValues = @[Animal(vdog), Animal(vcat)]
  var animalValuesArray = [Animal(vdog), Animal(vcat)]

  wantsNonCovariantSeq animalValues
  wantsNonCovariantArray animalValuesArray

reject wantsNonCovariantSeq(dogRefs)
reject modifiesCovariantOpenArray(dogRefs)
reject wantsNonCovariantArray(dogRefsArray)
reject wantsNonCovariantSeq(dogValues)
reject wantsNonCovariantArray(dogValuesArray)
reject modifiesValueArray()

modifiesDerivedOpenArray dogRefs
reject modifiesDerivedOpenArray(dogValues)
reject modifiesDerivedOpenArray(animalRefs)

reject wantsNonCovariantOpenArray(animalRefs)
reject wantsNonCovariantOpenArray(dogRefs)
reject wantsNonCovariantOpenArray(dogValues)

var animalRefSeq: seq[ref Animal]

accept:
  animalRefSeq = @[AnimalRef(dog), AnimalRef(dog)]
  animalRefSeq = @[AnimalRef(cat), dog]

acceptWithCovariance:
  animalRefSeq = @[makeDerivedRef("dog 1"), makeDerivedRef("dog 2")]
  wantsCovariantSeq1(animalRefSeq)
else:
  echo "dog 1"
  echo "dog 2"

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

# covariance may be allowed for certain extern types

{.emit: """/*TYPESECTION*/
template <class T> struct FN { typedef void (*type)(T); };
template <class T> struct ARR { typedef T DataType[2]; DataType data; };
""".}

type
  MyPtr[out T] {.importcpp: "'0 *"}  = object

  MySeq[out T] {.importcpp: "ARR<'0>", nodecl}  = object
    data: array[2, T]

  MyAction[in T] {.importcpp: "FN<'0>::type"}  = object

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
