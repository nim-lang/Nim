discard """
  targets: "js"
  errormsg: "'keys' is of type <varargs[string]> which cannot be captured as it would violate memory safety"
"""

# bug #14185: used to crash the JS backend
import std/json

type ProcedureType = proc(data: JsonNode): JsonNode

func get(keys: varargs[string]): ProcedureType =
  return proc(node: JsonNode): JsonNode =
    var res = node
    for key in items(keys): res = res[key]
    return res

var p: ProcedureType = get("name")
