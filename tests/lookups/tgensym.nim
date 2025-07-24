discard """
  output: "123100"
"""

template hygienic(val) =
  var x = val
  stdout.write x

var x = 100

hygienic 1
hygienic 2
hygienic 3

echo x

