# Runs `qzdimpl.depValue` at compile time: its NIF depends on that body. It
# fails to compile once that returns something else.
import qzdimpl

const midValue* = depValue()
static: doAssert midValue == 1
