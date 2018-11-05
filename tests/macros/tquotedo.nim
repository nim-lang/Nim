import macros

macro mac(): untyped =
  quote do:
    proc test(): int =
      (proc(): int = result = 123)()

mac()
echo test()

macro foobar(arg: untyped): untyped =
  result = arg
  result.add quote do:
    `result`

foobar:
  echo "Hallo Welt"
