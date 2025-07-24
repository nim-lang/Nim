let foo* {.deprecated: "abcd".} = 42
var foo1* {.deprecated: "efgh".} = 42
foo1 = foo #[tt.Warning
^ efgh; foo1 is deprecated [Deprecated]; tt.Warning
       ^ abcd; foo is deprecated [Deprecated]]#

proc hello[T](a: T) {.deprecated: "Deprecated since v1.2.0, use 'HelloZ'".} =
  discard

hello[int](12) #[tt.Warning
^ Deprecated since v1.2.0, use 'HelloZ'; hello is deprecated [Deprecated]]#

const foo2* {.deprecated: "abcd".} = 42
discard foo2 #[tt.Warning
        ^ abcd; foo2 is deprecated [Deprecated]]#
