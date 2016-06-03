discard """
  output: '''true
true'''
"""

# bug #4186
type
  Predicate[T] = proc(item: T): bool

proc a[T](): Predicate[T] =
  return nil

proc b[T](): Predicate[T] =
  return a[T]()

echo b[int]() == nil  # ok

let x = b[int]()
echo x == nil     #won't compile
