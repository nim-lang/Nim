type
  TFoo = ref object of TObject
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
