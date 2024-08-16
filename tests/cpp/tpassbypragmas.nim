discard """
  targets: "cpp"
  cmd: "nim cpp $file"
"""
{.emit:"""/*TYPESECTION*/

  template<typename T>
  struct Box {
      T first;
  };
  struct Foo {
  void test(void (*func)(Box<Foo>& another)){

    };
  };
""".}

type 
  Foo {.importcpp.} = object
  Box[T] {.importcpp:"Box<'0>".} = object
    first: T

proc test(self: Foo, fn: proc(another {.byref.}: Box[Foo]) {.cdecl.}) {.importcpp.}

proc fn(another {.byref.} : Box[Foo]) {.cdecl.} = discard

Foo().test(fn)