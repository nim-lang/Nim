discard """
nimout: '''
true
true
[nil, nil, nil, nil]
[MyObjectRef(123, 321), nil, nil, nil]
['A', '\x00', '\x00', '\x00']
MyObjectRef(123, 321)
(key: 8, val: 0)
'''
output: '''
true
true
[nil, nil, nil, nil]
[MyObjectRef(123, 321), nil, nil, nil]
['A', '\x00', '\x00', '\x00']
MyObjectRef(123, 321)
'''
"""

type
  MyObjectRef = ref object
    a,b: int

  MyContainerObject = ref object
    member: MyObjectRef

  MySuperContainerObject = ref object
    member: MyContainerObject
    arr: array[4, MyObjectRef]

  MyOtherObject = ref object
    case kind: bool
    of true:
      member: MyObjectRef
    else:
      discard

proc `$`(arg: MyObjectRef): string =
  result = "MyObjectRef("
  result.addInt arg.a
  result.add ", "
  result.addInt arg.b
  result.add ")"

proc foobar(dst: var MyObjectRef) =
  dst = new(MyObjectRef)
  dst.a = 123
  dst.b = 321

proc changeChar(c: var char) =
  c = 'A'

proc test() =
  # when it comes from a var, it works
  var y: MyObjectRef
  foobar(y)
  echo y != nil
  # when it comes from a member, it fails on VM
  var x = new(MyContainerObject)
  foobar(x.member)
  echo x.member != nil

  # when it comes from an array, it fails on VM
  var arr: array[4, MyObjectRef]
  echo arr
  foobar(arr[0])
  echo arr

  var arr2: array[4, char]
  changeChar(arr2[0])
  echo arr2


  var z = MyOtherObject(kind: true)
  foobar(z.member)
  echo z.member

  # this still doesn't work
  # var sc = new(MySuperContainerObject)
  # sc.member = new(MyContainerObject)
  # foobar(sc.member.member)
  # echo sc.member.member
  # foobar(sc.arr[1])
  # echo sc.arr

  #var str = "---"
  #changeChar(str[1])
  #echo str

test()
static:
  test()

type T = object
  f: seq[tuple[key, val: int]]

proc foo(s: var seq[tuple[key, val: int]]; i: int) =
  s[i].key = 4*i
  # r4 = addr(s[i])
  # r4[0] = 4*i

proc bar() =
  var s: T
  s.f = newSeq[tuple[key, val: int]](3)
  foo(s.f, 2)
  echo s.f[2]

static:
  bar()
