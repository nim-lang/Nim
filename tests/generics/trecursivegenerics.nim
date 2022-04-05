block: # Replicates #18728
  type
    FlipFlop[A, B] = ref object
      val: A
      next: FlipFlop[B, A]
  
    Trinary[A, B, C] = ref object
      next: Trinary[B, C, A]
  
  assert typeof(FlipFlop[int, string]().next) is FlipFlop[string, int]
  assert typeof(FlipFlop[string, int]().next) is FlipFlop[int, string]
  assert typeof(Trinary[int, float, string]().next) is Trinary[float, string, int]
  assert typeof(Trinary[int, float, string]().next.next) is Trinary[string, int, float]
  var a = FlipFlop[int, string](val: 100, next: FlipFlop[string, int](val: "Hello"))
  assert a.val == 100
  assert a.next.val == "Hello"

block: # 18838
  type
    DoublyLinkedNodeObj[T] = object
      value: T

    DoublyLinkedNode[T] = ref DoublyLinkedNodeObj[T]

    Item[T] = ref object
      link: DoublyLinkedNode[Item[T]]

    Box = object

  proc newDoublyLinkedNode[T](value: T): DoublyLinkedNode[T] =
    new(result)
    result.value = value 

  let link = newDoublyLinkedNode(Item[Box]())

import lists
block:
  type
    Box = object
    Item[T] = ref object
      link:DoublyLinkedNode[ Item[T] ]

    ItemSimple = ref object
      link:DoublyLinkedNode[ ItemSimple ]

  let link = newDoublyLinkedNode( Item[Box]() )

block: #18897
  type
    SkipListObj[T] = object
      over: SkipList[T]
      down: SkipList[T]
      value: T

    SkipList[T] = ref SkipListObj[T]

    GraphObj[N, E; F: static[int]] = object
      nodes: SkipList[Node[N, E]]

    Graph[N, E; F: static[int]] = ref GraphObj[N, E, F]

    Node[N, E] = ref NodeObj[N, E]

    NodeObj[N, E] = object
      value: N
      incoming: SkipList[Edge[N, E]]
      outgoing: SkipList[Edge[N, E]]

    Edge[N, E] = ref EdgeObj[N, E]

    EdgeObj[N, E] = object
      value: E
      id: int
      source: Node[N, E]
      target: Node[N, E]

    EdgeResult[N, E] = tuple
      source: Node[N, E]
      edge: Edge[N, E]
      target: Node[N, E]

  proc newSkipList[T](value: T): SkipList[T] =
    static: echo T, " ", typeof(result.value)
    result = SkipList[T](value: value)

  proc toSkipList[T](values: openArray[T] = @[]): SkipList[T] =
    for item in items(values):
      if result.isNil:
        result = newSkipList(item)

  proc newContainer[N, E, F](graph: Graph[N, E, F]; form: typedesc): auto =
    result = toSkipList[form]([])

  var
    result = Graph[int, string, 0]()
  result.nodes = result.newContainer(Node[int, string])