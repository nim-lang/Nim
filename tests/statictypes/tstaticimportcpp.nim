discard """
targets: "cpp"
output: "[0, 0, 10, 0]\n5\n1.2\n15\ntest"
"""

{.emit: """

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

a.data[2] = 10
b.field = 5
c.field = 1.2

echo a.data
echo b.field
echo c.field
echo d.field
echo e.field

