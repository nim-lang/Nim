## This module provides further logic operators like 'forall' and 'exists'
## They are only supported in ``.ensures`` etc pragmas.

proc `->`*(a, b: bool): bool {.magic: mImplies.}
proc `<->`*(a, b: bool): bool {.magic: mIff.}

proc forall*(args: varargs[untyped]): bool {.magic: mForall.}
proc exists*(args: varargs[untyped]): bool {.magic: mExists.}
