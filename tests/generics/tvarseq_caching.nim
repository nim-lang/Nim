discard """
  output: '''@[1, 2, 3]
@[4.0, 5.0, 6.0]
@[1, 2, 3]
@[4.0, 5.0, 6.0]
@[1, 2, 3]
@[4, 5, 6]'''
"""

# bug #3476

proc foo[T]: var seq[T] =
  ## Problem! Bug with generics makes every call to this proc generate
  ## a new seq[T] instead of retrieving the `items {.global.}` variable.
  var items {.global.}: seq[T]
  return items

proc foo2[T]: ptr seq[T] =
  ## Workaround! By returning by `ptr` instead of `var` we can get access to
  ## the `items` variable, but that means we have to explicitly deref at callsite.
  var items {.global.}: seq[T]
  return addr items

proc bar[T]: var seq[int] =
  ## Proof. This proc correctly retrieves the `items` variable. Notice the only thing
  ## that's changed from `foo` is that it returns `seq[int]` instead of `seq[T]`.
  var items {.global.}: seq[int]
  return items


foo[int]() = @[1, 2, 3]
foo[float]() = @[4.0, 5.0, 6.0]

foo2[int]()[] = @[1, 2, 3]
foo2[float]()[] = @[4.0, 5.0, 6.0]

bar[int]() = @[1, 2, 3]
bar[float]() = @[4, 5, 6]


echo foo[int]()      # prints 'nil' - BUG!
echo foo[float]()    # prints 'nil' - BUG!

echo foo2[int]()[]   # prints '@[1, 2, 3]'
echo foo2[float]()[] # prints '@[4.0, 5.0, 6.0]'

echo bar[int]()      # prints '@[1, 2, 3]'
echo bar[float]()    # prints '@[4, 5, 6]'
