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

when false:
  # todo fix me
  cyclicNo(LinkedNodeWithCursor)

type
  ObjectWithoutCycles = object
    data: seq[ObjectWithoutCycles]

cyclicNo(ObjectWithoutCycles)


block:
  type
    Try = object
      id: Best
    Best = object
      name: ref Try
    Best2 = ref Best

  cyclicYes(Best)
  cyclicYes(Try)
  cyclicNo(Best2)

  type
    Base = object
      data: ref seq[Base]
    Base2 = ref Base

  cyclicYes(Base)
  cyclicNo(Base2)


  type
    Base3 = ref object
      id: Base3

    Base4 = object
      id: ref Base4

  cyclicYes(Base3)
  cyclicYes(Base4)
  cyclicYes(ref Base4)

block:
  type Cyclic2 = object
    x: ref (Cyclic2, int)

  cyclicYes (Cyclic2, int)
  cyclicYes (ref (Cyclic2, int))

block:
  type
    myseq[T] = object
      data: ptr UncheckedArray[T]
    Node = ref object
      kids: myseq[Node]

  cyclicNo(Node)

block:
  type
    myseq[T] = object
      data: ptr UncheckedArray[T]
    Node = ref object
      kids: myseq[Node]

  proc `=trace`(x: var myseq[Node]; env: pointer) = discard

  cyclicYes(Node)
