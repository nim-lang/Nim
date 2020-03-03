discard """
  targets: "cpp"
  output: "42"
"""

# bug #2324

static: assert defined(cpp), "compile in cpp mode"

{.emit: """
class Foo {
public:
    static int x;
};
int Foo::x = 42;
""".}

type Foo {.importcpp:"Foo".} = object
proc x* (this: typedesc[Foo]): int {.importcpp:"Foo::x@", nodecl.}
echo Foo.x
