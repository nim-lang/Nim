discard """
targets: "cpp"
output: "[0, 0, 10, 0]\n5\n1.2\n15\ntest\n[0, 0, 20, 0]\n4"
"""

{.emit: """/*TYPESECTION*/

template <int N, class T>
struct GenericIntType {
  T data[N];
};

template <class T>
struct GenericTType {
  T field;
};

struct SimpleStruct {
  int field;
};


""" .}

type
  GenericIntType {.importcpp: "GenericIntType<'0, '1>".} [N: static[int]; T] = object
    data: array[N, T]

  GenericIntTypeAlt {.importcpp: "GenericIntType".} [N: static[int]; T] = object

  GenericTType {.importcpp: "GenericTType<'0>".} [T] = object
    field: T

  GenInt4 = GenericIntType[4, int]

  SimpleStruct {.importcpp: "SimpleStruct"} = object
    field: int

var
  a = GenInt4()
  b = SimpleStruct()
  c = GenericTType[float]()
  d = SimpleStruct(field: 15)
  e = GenericTType[string](field: "test")
  f = GenericIntTypeAlt[4, int8]()

a.data[2] = 10
b.field = 5
c.field = 1.2

echo a.data
echo b.field
echo c.field
echo d.field
echo e.field

proc plus(a, b: GenInt4): GenInt4 =
  for i in 0 ..< result.data.len:
    result.data[i] = a.data[i] + b.data[i]

echo plus(a, a).data

echo sizeof(f)
