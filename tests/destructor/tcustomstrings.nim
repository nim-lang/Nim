discard """
  output: '''foo bar to appendmore here
foo bar to appendmore here
foo bar to appendmore here
foo bar to appendmore here
foo bar to appendmore here
after 20 20'''
joinable: false
"""

{.this: self.}

type
  mystring = object
    len, cap: int
    data: ptr UncheckedArray[char]

var
  allocCount, deallocCount: int

proc `=destroy`*(s: var mystring) =
  if s.data != nil:
    dealloc(s.data)
    inc deallocCount
    s.data = nil
    s.len = 0
    s.cap = 0

proc `=sink`*(a: var mystring, b: mystring) =
  # we hope this is optimized away for not yet alive objects:
  if a.data != nil and a.data != b.data:
    dealloc(a.data)
    inc deallocCount
  a.len = b.len
  a.cap = b.cap
  a.data = b.data

proc `=`*(a: var mystring; b: mystring) =
  if a.data != nil and a.data != b.data:
    dealloc(a.data)
    inc deallocCount
    a.data = nil
  a.len = b.len
  a.cap = b.cap
  if b.data != nil:
    a.data = cast[type(a.data)](alloc(a.cap + 1))
    inc allocCount
    copyMem(a.data, b.data, a.cap+1)

proc resize(self: var mystring) =
  if self.cap == 0: self.cap = 8
  else: self.cap = (self.cap * 3) shr 1
  if self.data == nil: inc allocCount
  self.data = cast[type(data)](realloc(self.data, self.cap + 1))

proc add*(self: var mystring; c: char) =
  if self.len >= self.cap: resize(self)
  self.data[self.len] = c
  self.data[self.len+1] = '\0'
  inc self.len

proc ensure(self: var mystring; newLen: int) =
  if newLen >= cap:
    cap = max((cap * 3) shr 1, newLen)
    if cap > 0:
      if data == nil: inc allocCount
      data = cast[type(data)](realloc(data, cap + 1))

proc add*(self: var mystring; y: mystring) =
  let newLen = len + y.len
  ensure(self, newLen)
  copyMem(addr data[len], y.data, y.data.len + 1)
  len = newLen

proc create*(lit: string): mystring =
  let newLen = lit.len
  ensure(result, newLen)
  copyMem(addr result.data[result.len], unsafeAddr lit[0], newLen + 1)
  result.len = newLen

proc `&`*(a, b: mystring): mystring =
  result = a
  result.add b

proc main(n: int) =
  var a: mystring
  let b = create" to append"
  for i in 0..<n:
    if i > 4: break
    a = create"foo bar"
    let c = b & create"more here"
    a.add c
    echo cstring(a.data)

  var x: array[4, mystring]
  for i in 0..high(x): x[i] = create"added to array"

main(1000)
echo "after ", allocCount, " ", deallocCount
