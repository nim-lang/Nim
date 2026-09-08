discard """
  description: '''IC vs `nim c`: a closure iterator nested in a closure iterator'''
"""

#? metamorphic

# `env.:up = enclosingEnv` links a nested routine's environment to its parent,
# and the two environments then reference each other. That assignment has to go
# through `=copy` (with the cyclic increment) or the parent's refcount is one too
# low, and at teardown both `=destroy`s believe they hold the last reference and
# recurse until the stack is gone — a SIGSEGV, after the program's own output has
# already been printed. (`tests/iter/tnestedclosures.nim`, "Test 3".)
#
# Whether it becomes a `=copy` depends on the up-field type's hooks existing when
# the routine is destructor-injected. Whole-program cgen got that for free: a
# LATER lifting pass creates them, and it runs before any routine's injection.
# The per-module backend injects a routine right after lifting it (the `lower`
# stage), long before the module's top level is transformed at all (that is
# `cg`) — so the hooks are created at the assignment site now.

#!FILE main.nim
iterator foo(): int {.closure.} =
  let x = 34
  proc bar() = echo "bar sees ", x
  iterator bar2(): int {.closure.} =
    bar()
    yield x
  for y in bar2():
    yield y

for v in foo(): echo v

# a closure iterator nested in a closure iterator, inside a proc
proc factory() =
  iterator outerIt(): int {.closure.} =
    iterator innerIt(): int {.closure.} =
      yield 0
      yield 1
      yield 2
    for x in innerIt(): yield x
  for x in outerIt(): echo x
factory()

# the iterator's env outlives the proc that made it
proc keep(): iterator (): string =
  let held = "kept"
  result = iterator (): string =
    yield held
    yield held & "!"
for s in keep()(): echo s
#!STEP

# growing the captured state changes both env layouts
#!FILE main.nim
iterator foo(): int {.closure.} =
  let x = 34
  var log: seq[string] = @[]
  proc bar() =
    log.add "bar"
    echo "bar sees ", x, " ", log.len
  iterator bar2(): int {.closure.} =
    bar()
    bar()
    yield x
  for y in bar2():
    yield y

for v in foo(): echo v

proc factory() =
  iterator outerIt(): int {.closure.} =
    var emitted = 0
    iterator innerIt(): int {.closure.} =
      yield 0
      yield 1
      yield 2
    for x in innerIt():
      inc emitted
      yield x * emitted
  for x in outerIt(): echo x
factory()

proc keep(): iterator (): string =
  let held = "kept"
  let extra = "+"
  result = iterator (): string =
    yield held & extra
    yield held & "!" & extra
for s in keep()(): echo s
#!STEP
