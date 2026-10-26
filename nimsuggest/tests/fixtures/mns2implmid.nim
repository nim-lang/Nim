# Runs `qzdimpl.depValue` at compile time: its NIF depends on that body.
import qzdimpl

const midValue* = depValue()
