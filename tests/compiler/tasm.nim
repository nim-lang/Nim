{.passC: "-std=c99".}

block asmTest:
  when defined(gcc):
    let src = 41
    var dst = 0

    asm """
      mov %1, %0\n\t
      add $1, %0
      : "=r" (`dst`)
      : "r" (`src`)"""

    doAssert dst == 42