import atomicSample

block crossFileObjectContainingAGenericWithAComplexObject:
  discard initAtomicWithGeneric[string]("foo")

block crossFileObjectContainingAGenericWithAnInteger:
  discard initAtomicWithGeneric[int](1)
  discard initAtomicWithGeneric[int8](1)
  discard initAtomicWithGeneric[int16](1)
  discard initAtomicWithGeneric[int32](1)
  discard initAtomicWithGeneric[int64](1)
