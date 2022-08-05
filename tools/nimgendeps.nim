import std/[osproc, strformat, os, json, strutils, parseopt]


proc handleMakeEscape(src: string): string =
  for i in 0..<src.len:
    if src[i] == '#':
      result.add '\\'
    elif src[i] == ' ':
      result.add '\\'
      let j = i - 1
      while j > 0 and src[j] == '\\':
        result.add '\\'
    elif src[i] == '$':
      result.add '$'
    result.add src[i]


proc writeDepfile(src: string, nimOption: var string, outFile: var string) =
  let filename = extractFilename(src)
  let jsonFile = filename.changeFileExt("json")
  let nimcacheDir = getTempDir() / "nimgccdeps"
  if nimOption.len == 0:
    nimOption = "c"
  let (msg, exitCode) = execCmdEx(fmt"nim {nimOption} --d:nimBetterRun --nimcache:{nimcacheDir} {src}")
  doAssert exitCode == 0, msg
  let jsonData = parseJson(readFile(nimcacheDir / jsonFile))
  let deps = jsonData["depfiles"]
  var f: File
  if outFile.len == 0:
    f = stdout
  else:
    f = open(outFile, fmWrite)
  try:
    let target = src.handleMakeEscape()
    f.write(target & ": \\" & '\n')

    for i in 0 ..< deps.len-1:
      let path = deps[i][0].getStr.handleMakeEscape()
      f.write('\t' & path & " \\" & '\n')
    let path = deps[^1][0].getStr.handleMakeEscape()
    f.write('\t' & path)
  finally:
    f.close()


proc main() =
  var p = initOptParser()
  var nimOption = ""
  var outFile = ""
  var src = ""
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdLongOption:
      if p.key.cmpIgnoreStyle("passnim") == 0:
        nimOption = p.val
      elif p.key.cmpIgnoreStyle("out") == 0:
        outFile = p.val
    of cmdShortOption:
      if p.key == "o":
        outFile = p.val
    of cmdArgument:
      src = p.key
      break

  if src.len == 0:
    echo "Please provides the input file"
  else:
    writeDepfile(src, nimOption, outFile)

main()
