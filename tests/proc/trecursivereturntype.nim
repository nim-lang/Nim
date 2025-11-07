# issue #7706

type
  Op = enum
    Halt
    Inc
    Dec

type
  InstrNext = proc (val: var int, code: seq[Op], pc: var int, stop: var bool): OpH {.inline, nimcall.}

  OpH = object
    handler: InstrNext

var a: OpH
