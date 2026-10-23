discard """
  action: run
  output: "ok"
"""

# Effects raised inside a `when nimvm` branch must not be attributed to the
# routine when compiling for run time: that branch is not part of the generated
# code. refs #26049

var global: string

proc gcSafety(): string {.gcsafe.} =
  when nimvm:
    result = global
  else:
    result = "ok"

type VmEffect = object of RootEffect

proc vmOnly() {.tags: [VmEffect].} = discard

proc tagsTracking() {.tags: [].} =
  when nimvm:
    vmOnly()
  else:
    discard

proc raisesTracking() {.raises: [].} =
  when nimvm:
    raise newException(ValueError, "vm only")
  else:
    discard

tagsTracking()
raisesTracking()
echo gcSafety()
