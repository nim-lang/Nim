import std/private/jsutils

proc main()=
  template fn(a): untyped = jsConstructorName(a)
  doAssert fn(array[2, int8].default) == "Int8Array"
  doAssert fn(array[2, uint8].default) == "Uint8Array"
  doAssert fn(array[2, byte].default) == "Uint8Array"
  # doAssert fn(array[2, char].default) == "Uint8Array" # xxx fails; bug?
  doAssert fn(array[2, uint64].default) == "Array"
    # pending https://github.com/nim-lang/RFCs/issues/187 maybe use `BigUint64Array`
  doAssert fn([1'u8]) == "Uint8Array"
  doAssert fn([1'u16]) == "Uint16Array"
  doAssert fn([byte(1)]) == "Uint8Array"

main()
