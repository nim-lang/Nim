# issue #24864

type S = distinct uint16
converter d(field: uint8 | uint16): S = discard
discard (repr(0'u16), repr(0'u8))
