discard """
  targets: "c cpp"
  action: compile
  ccodeCheck: "@'__asm__ __volatile__(' .*"
  ccodeCheck: "@'__asm__(' .*"
"""

# bug #26649: `asm` statements inside procs are emitted with `volatile` so
# that the C compiler cannot merge, hoist or drop them. A top-level `asm`
# is emitted at file scope, where `volatile` is rejected, and stays plain.

asm """
  nop
"""

proc probe(): uint64 =
  var r: uint64
  asm """
    nop
    : "=r"(`r`)
  """
  r

discard probe()
