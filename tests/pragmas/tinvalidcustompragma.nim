discard """
  cmd: "nim check $file"
"""

# issue #21652
type Foo = object
template foo() {.tags:[Foo].} = #[tt.Error
                     ^ invalid pragma: tags: [Foo]]#
  discard

{.foobar.} #[tt.Error
  ^ invalid pragma: foobar]#
type A = enum a {.foobar.} #[tt.Error
                  ^ invalid pragma: foobar]#
for b {.foobar.} in [1]: discard #[tt.Error
        ^ invalid pragma: foobar]#
template foobar {.pragma.}
{.foobar.} #[tt.Error
  ^ cannot attach a custom pragma to 'tinvalidcustompragma'; custom pragmas are not supported for modules]#
type A = enum a {.foobar.} #[tt.Error
                  ^ cannot attach a custom pragma to 'a'; custom pragmas are not supported for enum fields]#
for b {.foobar.} in [1]: discard #[tt.Error
        ^ cannot attach a custom pragma to 'b'; custom pragmas are not supported for `for` loop variables]#
