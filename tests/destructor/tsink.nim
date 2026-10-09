discard """
  targets: "c cpp"
  matrix: "--mm:refc; --mm:arc"
"""

type AnObject = object of RootObj
  value*: int

proc mutate(shit: sink AnObject) =
  shit.value = 1

proc foo = # bug #23359
  var bar = AnObject(value: 42)
  mutate(bar)
  doAssert bar.value == 42

foo()

block: # bug #23902
  proc foo(a: sink string): auto = (a, a)

  proc bar(a: sink int): auto = return a

  proc foo(a: sink string) =
    var x = (a, a)

block: # bug #24175
  block:
    func mutate(o: sink string): string =
      o[1] = '1'
      result = o

    static:
      let s = "999"
      let m = mutate(s)
      doAssert s == "999"
      doAssert m == "919"

    func foo() =
      let s = "999"
      let m = mutate(s)
      doAssert s == "999"
      doAssert m == "919"

    static:
      foo()
    foo()

  block:
    type O = object
      a: int

    func mutate(o: sink O): O =
      o.a += 1
      o

    static:
      let x = O(a: 1)
      let y = mutate(x)
      doAssert x.a == 1
      doAssert y.a == 2

    proc foo() =
      let x = O(a: 1)
      let y = mutate(x)
      doAssert x.a == 1
      doAssert y.a == 2

    static:
      foo()
    foo()

proc create(value: sink int): ptr int =
  let s = addr value
  result = addr value
  result = s


let xxx = create(12)

block issue26410:
  # Resizing a sink parameter must not write into literal or constant storage.
  # Keep setLen as the only mutation so other writes cannot trigger a sink copy.
  const values = @[1, 2, 3]

  proc resizeString(s: sink string; length: int) =
    s.setLen(length)
    doAssert s.len == length
    if length <= 7:
      doAssert s == "literal"[0..<length]

  proc resizeSeq(s: sink seq[int]; length: int) =
    s.setLen(length)
    doAssert s.len == length
    for i in 0..<min(length, values.len):
      doAssert s[i] == values[i]
    for i in values.len..<length:
      doAssert s[i] == 0

  proc resizeSeqUninit(s: sink seq[int]; length: int) =
    s.setLenUninit(length)
    doAssert s.len == length
    for i in 0..<min(length, values.len):
      doAssert s[i] == values[i]

  for length in [0, 2, 7, 12]:
    resizeString("literal", length)
  for length in [0, 2, 3, 12]:
    resizeSeq(values, length)
    resizeSeqUninit(values, length)

  type Box = object
    text: string
    items: seq[int]

  const
    box = Box(text: "literal", items: values)
    pair = (text: "literal", items: values)

  proc resizeObject(b: sink Box) =
    b.text.setLen(2)
    b.items.setLen(2)
    doAssert b.text == "li"
    doAssert b.items == @[1, 2]

  proc resizeTuple(t: sink tuple[text: string, items: seq[int]]) =
    t.text.setLen(t.text.len)
    t.items.setLen(t.items.len)
    doAssert t.text == "literal"
    doAssert t.items == values

  resizeObject(box)
  resizeTuple(pair)

  # Calls must also preserve caller-owned values that are read afterwards.
  var text = "literal"
  var items = @[1, 2, 3]
  resizeString(text, 2)
  resizeSeq(items, 2)
  resizeSeqUninit(items, 2)
  doAssert text == "literal"
  doAssert items == values
  doAssert box.text == "literal" and box.items == values
  doAssert pair.text == "literal" and pair.items == values
