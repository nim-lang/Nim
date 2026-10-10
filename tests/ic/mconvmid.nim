# Helper for tconverterreexport.nim: re-exports mconvbase and provides a
# `mixin`-using template whose expansion in the consumer relies on the
# re-exported `toReal` converter (Handle -> Real) for `init`. Mirrors
# ssz_serialization re-exporting serialization/faststreams and its `decode`
# template needing the implicit stream conversion at `init(Reader, stream)`.
import mconvbase
export mconvbase

template decode*(): auto =
  mixin init, readVal
  var h = Handle(x: 5)
  var r = init(Reader, h)   # requires the re-exported converter toReal
  readVal(r)
