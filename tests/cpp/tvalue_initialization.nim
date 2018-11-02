discard """
  targets: "cpp"
"""

{.emit: """/*TYPESECTION*/
struct Foo
{
  bool isConstructed = true;
};
""".}

type
  Foo {.importc.} = object

  Bar = object
    impl: Foo

proc isConstructed(self: Foo): bool {.importcpp: "#.$1".}

proc test_init_locals(): Bar =
  var
    x: Bar
    y: (Foo, Bar)
    z = Bar()

  doAssert result.impl.isConstructed
  doAssert x.impl.isConstructed
  doAssert y[0].isConstructed
  doAssert y[1].impl.isConstructed
  doAssert z.impl.isConstructed

proc test_reset(): Bar =
  if true:
    result = Bar()

  doAssert result.impl.isConstructed

discard test_init_locals()
discard test_reset()
