# bug #2540

type
  BaseSceneNode[T] = ref object of RootObj
    children*: seq[BaseSceneNode[T]]
    parent*: BaseSceneNode[T]

  SceneNode[T] = ref object of BaseSceneNode[T]

  SomeObj = ref object

proc newSceneNode[T](): SceneNode[T] =
  new result
  result.children = @[]

var aNode = newSceneNode[SomeObj]()


# bug #3038

type
  Data[T] = ref object of RootObj
    data: T
  Type = ref object of RootObj
  SubType[T] = ref object of Type
    data: Data[T]
  SubSubType = ref object of SubType
  SubSubSubType = ref object of SubSubType
