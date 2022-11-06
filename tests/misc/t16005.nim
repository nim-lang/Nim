var x = 0

block:
  type Foo = object
    x: float # ok

template main() =
  block:
    type Foo = object
      x: float # Error: cannot use symbol of kind 'var' as a 'field'

main()
