when pointer.sizeof == 8:
  #issue #20024
  type Foo = enum
    A = 0u32
    B = 0x8000_0000u32

  type Bar = enum
    C = A

  type Baz = enum
    D = (B, "Actually D")

  converter toFoo(a: uint32): Foo = Foo(a)
  converter fromFoo(a: Foo): uint32 = uint32(a)
  converter toBar(a: uint32): Bar = Bar(a)
  converter toBaz(a: uint32): Baz = Baz(a)

  var g:Foo = 0u32 or B
  var h:Bar = 0u32 and A
  var i:Baz = 0x8000_0000u32

  doAssert g == B
  doAssert h == C
  doAssert i == D