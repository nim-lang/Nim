when true:
  echo "hello world"
else:
  proc unused() =
    discard "goats"

  proc hellow() =
    echo "hello world"

  hellow()
