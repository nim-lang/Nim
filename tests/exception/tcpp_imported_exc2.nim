discard """
targets: "cpp"
output: ""
"""
#issue #14369 case 2
type RuntimeError {.requiresInit, importcpp: "std::runtime_error", header: "<stdexcept>".} = object

proc initRuntimeError(a: cstring): RuntimeError {.importcpp: "std::runtime_error(@)", constructor.}
try: raise initRuntimeError("foo2")
except: discard
