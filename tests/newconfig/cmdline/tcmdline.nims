from std/strutils import endsWith, join
from std/os import commandLineParams
import std/parseopt

let cmdParams = commandLineParams().join(", ")
var
 rawHasNims = false
 rawHasMain = false
 parsed: seq[string]

for i in 1..paramCount():
  let arg = paramStr(i)
  rawHasNims = rawHasNims or arg.endsWith(".nims")
  rawHasMain = rawHasMain or arg.endsWith("test.nim")

# parseopt follows commandLineParams for NimScript.
var p = initOptParser()
for _, key, val in p.getopt():
  parsed.add key

echo "nims cmdline test:\n",
  "  scriptArgs=[", cmdParams, "]; (paramCount > 0)==", paramCount() > 0,
  "; rawHasNims=", rawHasNims, "; rawHasMain=", rawHasMain, ";\n",
  "  parseopt got args: ", parsed.len
