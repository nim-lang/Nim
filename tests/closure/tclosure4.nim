
import json, tables, sequtils

proc run(json_params: Table) =
  let json_elems = json_params["files"].elems
  # These fail compilation.
  var files = map(json_elems, proc (x: JsonNode): string = x.str)
  #var files = json_elems.map do (x: JsonNode) -> string: x.str
  echo "Hey!"

when isMainModule:
  let text = """{"files": ["a", "b", "c"]}"""
  run((text.parseJson).fields)
