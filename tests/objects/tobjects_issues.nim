discard """
  output: '''
tbObj of TC true
true
5
true
is Nil false
'''
"""


block t1053:
  type
    TA = object of RootObj
      a: int
    TB = object of TA
      b: int
    TC = object of TB
      c: int

  proc test(p: TA) =
    if p of TB:
      echo "tbObj of TC ", p of TC

  var v = TC()
  v.a = 1
  v.b = 2
  v.c = 3
  test(v)



block t924:
  type
    MyObject = object of RootObj
      x: int
  var asd: MyObject

  proc isMyObject(obj: RootObj) =
      echo obj of MyObject
      if obj of MyObject:
          let a = MyObject(obj)
          echo a.x

  asd.x = 5
  isMyObject(asd)



block t4673:
  type
    BaseObj[T] = ref object of RootObj
    SomeObj = ref object of BaseObj[int]

  proc doSomething[T](o: BaseObj[T]) =
    echo "true"
  var o = new(SomeObj)
  o.doSomething() # Error: cannot instantiate: 'T'



block t1658:
  type
    Loop = ref object
      onBeforeSelect: proc (L: Loop)

  var L: Loop
  new L
  L.onBeforeSelect = proc (bar: Loop) =
    echo "is Nil ", bar.isNil

  L.onBeforeSelect(L)



block t2508:
  type
    GenericNodeObj[T] = ref object
      obj: T
    Node = ref object
      children: seq[Node]
      parent: Node
      nodeObj: GenericNodeObj[int]

  proc newNode(nodeObj: GenericNodeObj): Node =
    result = Node(nodeObj: nodeObj)
    newSeq(result.children, 10)

  var genericObj = GenericNodeObj[int]()
  var myNode = newNode(genericObj)



block t2540:
  type
    BaseSceneNode[T] = ref object of RootObj
      children: seq[BaseSceneNode[T]]
      parent: BaseSceneNode[T]
    SceneNode[T] = ref object of BaseSceneNode[T]
    SomeObj = ref object

  proc newSceneNode[T](): SceneNode[T] =
    new result
    result.children = @[]

  var aNode = newSceneNode[SomeObj]()


block t3038:
  type
    Data[T] = ref object of RootObj
      data: T
    Type = ref object of RootObj
    SubType[T] = ref object of Type
      data: Data[T]
    SubSubType = ref object of SubType[int]
    SubSubSubType = ref object of SubSubType
