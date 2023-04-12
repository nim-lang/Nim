# issue #21652

type
  Foo = object

template foo() {.tags:[Foo].} = #[tt.Error
                     ^ invalid pragma: tags: [Foo]]#
  discard
