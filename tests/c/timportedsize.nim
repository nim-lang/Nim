{.emit: """
typedef struct Foo {
  NI64 a;
  NI64 b;
} Foo;
""".}

type Foo {.importc: "Foo", size: 16.} = object

var x: Foo
