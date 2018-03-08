discard """
  output: '''TBar2
TFoo
16
12
16
12'''
"""

## XXX this output needs to be adapated for VCC which produces different results.

# It turned out that it's hard to generate correct for these two test cases at
# the same time.

type
  TFoo = ref object of RootObj
    Data: int
  TBar = ref object of TFoo
    nil
  TBar2 = ref object of TBar
    d2: int

template super(self: TBar): TFoo = self

template super(self: TBar2): TBar = self

proc Foo(self: TFoo) =
  echo "TFoo"

#proc Foo(self: TBar) =
#  echo "TBar"
#  Foo(super(self))
# works when this code is uncommented

proc Foo(self: TBar2) =
  echo "TBar2"
  Foo(super(self))

var b: TBar2
new(b)

Foo(b)

# bug #837
type
  PView* = ref TView
  TView* {.inheritable.} = object
    data: int

  PWindow* = ref TWindow
  TWindow* = object of TView
    data3: int

  PDesktop* = ref TDesktop
  TDesktop* = object of TView
    data2: int

proc makeDesktop(): PDesktop = new(TDesktop)

proc makeWindow(): PWindow = new(TWindow)

proc thisCausesError(a: PView, b: PView) =
  discard

var dd = makeDesktop()
var aa = makeWindow()

thisCausesError(dd, aa)

# bug #4763
type
  testObject_1 = object
    size: int32
    value: int64

  testObject_2 {.packed.} = object
    size: int32
    value: int64

  testObject_3[T] = object
    size: int32
    value: T

  testObject_4 {.packed.} [T] = object
    size: int32
    value: T

echo sizeof(testObject_1)
echo sizeof(testObject_2)
echo sizeof(testObject_3[int64])
echo sizeof(testObject_4[int64])

# bug  #5892
type
    Foo6 = distinct array[4, float32]
    AnotherFoo = distinct array[4, float32]

    AbstractAnimationSampler* = ref object of RootObj

    AnimationSampler*[T] = ref object of AbstractAnimationSampler
        sampleImpl: proc(s: AnimationSampler[T], p: float): T

    ArrayAnimationSampler*[T] = ref object of AnimationSampler[T]

proc newArrayAnimationSampler*[T](): ArrayAnimationSampler[T] =
    result.new()
    result.sampleImpl = nil

discard newArrayAnimationSampler[Foo6]()
discard newArrayAnimationSampler[AnotherFoo]()
