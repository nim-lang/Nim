import macros

macro mac(): untyped =
  quote do:
    proc test(): int =
      (proc(): int = result = 123)()

mac()
echo test()
