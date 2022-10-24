import m1027a, m1027b

# bug #1027
template wrap_me(stuff): untyped =
  echo "Using " & version_str

wrap_me("hey")
