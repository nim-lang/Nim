import atomicSample

block crossFileObjectContainingAGeneric:
  discard initAtomicWithGeneric[string]("foo")

