discard """
  targets: "cpp"
  errormsg: "cppExternalDefault is a sentinel only valid as a generic parameter default on importcpp types"
  line: 12
"""

# Triggers the lib/system.nim cppExternalDefault template's {.error.} when
# the user calls the sentinel directly instead of using it as a generic
# parameter default. Should fail to compile with a clear message.

proc main() =
  discard cppExternalDefault[int]()

main()
