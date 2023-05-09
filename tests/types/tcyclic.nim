## todo publish the `isCyclic` when it's mature.
proc isCyclic(t: typedesc): bool {.magic: "TypeTrait".} =
  ## Returns true if the type can potentially form a cyclic type

template cyclicYes(x: typed) =
  doAssert isCyclic(x)

template cyclicNo(x: typed) =
  doAssert not isCyclic(x)

# atomic types are not cyclic
cyclicNo(int)
cyclicNo(float)
cyclicNo(string)
cyclicNo(char)
cyclicNo(void)

type
  Object = object
  Ref = ref object

cyclicNo(Object)
cyclicNo(Ref)

type
  Data1 = ref object
  Data2 = ref object
    id: Data1

cyclicNo(Data2)

type
  Cyclone = ref object
    data: Cyclone

  Alias = Cyclone

  Acyclic {.acyclic.} = ref object
    data: Acyclic

  LinkedNode = object
    next: ref LinkedNode

  LinkedNodeWithCursor = object
    next {.cursor.} : ref LinkedNodeWithCursor

cyclicYes(Cyclone)
cyclicYes(Alias)
cyclicNo(seq[Cyclone])
cyclicNo((Cyclone, ))
cyclicNo(Acyclic)

cyclicYes(LinkedNode)
# todo fix me
# cyclicNo(LinkedNodeWithCursor)
