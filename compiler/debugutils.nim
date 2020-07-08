#[
see also ./debugutils_basic
]#

import ./debugutils_basic
export debugutils_basic

when withDebugutils:
  defineNoop:
    dbg
    dbg2

elif withDebugutilsTimn:
  import timn/compilerutils/nimc_interface2 # D20200619T192931
  export nimc_interface2

else:
  defineNoop:
    dbg
    dbg2
