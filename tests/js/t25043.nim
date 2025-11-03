discard """
  action: "compile"
"""

proc audit*(event: string, args: varargs[string]) = discard
# args is `varargs[Any]` in real world code

type PathLike[T] = concept self
  $self is T  # a simplified definition

proc utime[T](path: PathLike[T]) =
  audit("os.utime", $path)

when isMainModule:
  utime("sad")
