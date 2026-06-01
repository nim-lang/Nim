discard """
  matrix: "--mm:refc"
"""
type
  State = enum
    Uninit
    Init
  Uart[T: static State] = object
    baudRate: int
    port: int

proc `=destroy`(uart: var Uart[Init]) = raiseAssert "Destroyed"

# proc `=copy`(a: var Uart[Init], b: Uart[Init]) {.error.} # Error: signature for '=copy' must be proc[T: object](x: var T; y: T)

proc main() =
  var a = Uart[Uninit]()

main()