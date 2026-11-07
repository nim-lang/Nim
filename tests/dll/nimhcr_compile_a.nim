{.compile: "nimhcr_compile.c".}

# without a header, the prototype is generated
proc nimhcrCompileAnswer*(x: cint): cint {.importc.}
# with a header, the C declaration is used
proc nimhcrCompileHeader*(x: cint): cint {.importc, header: "nimhcr_compile.h".}

proc answer*(): int = int(nimhcrCompileAnswer(20))
proc headerAnswer*(): int = int(nimhcrCompileHeader(1))
