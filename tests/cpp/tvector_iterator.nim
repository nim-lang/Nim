discard """
  targets: "cpp"
"""

{.emit: """/*TYPESECTION*/

template <class T>
struct Vector {
  struct Iterator {};
};

""".}

type
  Vector[T] {.importcpp: "Vector".} = object
  VectorIterator[T] {.importcpp: "Vector<'0>::Iterator".} = object

var x: VectorIterator[void]

