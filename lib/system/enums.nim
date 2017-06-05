import macros

# XXX: https://github.com/nim-lang/Nim/issues/5881
macro setImpl(T: typedesc[enum]): auto =
    result = newNimNode(nnkCurly)
    for T in T.getType[1]:
        if T.kind != nnkEmpty: result.add T

# XXX: it should be possible to apply 'compileTime' to this proc
proc set*(T: typedesc[enum]): auto =
    ## generates a set that contains all the members of the enum type `T`.
    ## It's currently not possible to specify the concrete return type
    ## (set[T]).
    T.setImpl