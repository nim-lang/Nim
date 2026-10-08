proc typeName*(T: typedesc): string {.compileTime.} = $T
