discard """
  targets: "cpp"
  action: compile
"""
import atomics

template relaxed*[T](location: var Atomic[T], value: T) =
  ## use template avoid copy Atomic[T] to temporary variable
  location.store(value, moRelaxed)

var atom: Atomic[int]
atom.relaxed(1)
atom.relaxed(2)
