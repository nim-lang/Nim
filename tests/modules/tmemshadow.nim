discard """
  output: '''17'''
"""

# bug: `import mmemshadow` and `template mmemshadow` both land in the top level
# scope; the template is the declaration, the module name is only what the
# import happened to be called, so `mmemshadow.read16(x)` must be a call to
# `read16(mmemshadow, x)` and not a qualified call into the module.

import mmemshadow

type CPU = object
  mmemshadow: CPUMemory

template mmemshadow: untyped {.dirty.} = cpu.mmemshadow

proc reset(cpu: var CPU) =
  cpu.mmemshadow.data[0] = 17
  echo mmemshadow.read16(0xFFFC)

var cpu = CPU()
cpu.reset()
