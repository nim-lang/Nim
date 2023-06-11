proc foo(x: int) = discard
proc foo(x: float) = discard

{.emit: ["// ", foo].} #[tt.Error
                ^ ambiguous identifier 'foo' -- use one of the following:
  tambiguousemit.foo: proc (x: int){.noSideEffect, gcsafe.}
  tambiguousemit.foo: proc (x: float){.noSideEffect, gcsafe.}]#
