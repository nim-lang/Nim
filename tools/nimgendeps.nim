import std/[osproc, strformat, os, json, strutils, parseopt]

const helpText = """
Usage:
  nimgendeps [options] file
Options:
  --passNim:options        the compile options passed to the Nim compiler
  --nim:path               use specified path for nim binary
  --nimcache:path          use specified path for nimcache
  --out:path, --o:path     specified path for the generated deps file
"""

type
  DepOption = ref object
    passNim, nimBinary, nimcacheDir, outFile: string

proc handleMakeEscape(src: string): string =
  for i in 0..<src.len:
    if src[i] == '#':
      result.add '\\'
    elif src[i] == ' ':
      result.add '\\'
      var j = i - 1
      while j >= 0 and src[j] == '\\':
        result.add '\\'
        dec j
    elif src[i] == '$':
      result.add '$'
    result.add src[i]

proc writeDepfile(src: string, option: DepOption) =
  let filename = extractFilename(src)
  let jsonFile = filename.changeFileExt("json")
  if option.nimcacheDir.len == 0:
    option.nimcacheDir = getTempDir() / "nimgccdeps"
  if option.passNim.len == 0:
    option.passNim = "c"
  if option.nimBinary.len == 0:
    option.nimBinary = "nim"
  let (msg, exitCode) = execCmdEx(fmt"{option.nimBinary} {option.passNim} --d:nimBetterRun --nimcache:{option.nimcacheDir} {src}")
  doAssert exitCode == 0, msg
  let jsonData = parseJson(readFile(option.nimcacheDir / jsonFile))
  let deps = jsonData["depfiles"]
  var f: File
  if option.outFile.len == 0:
    f = stdout
  else:
    f = open(option.outFile, fmWrite)
  try:
    let target = src.changeFileExt(when defined(windows): ".exe" else: "").handleMakeEscape()
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
  var passNim = ""
  var outFile = ""
  var src = ""
  var nimBinary = ""
  var nimcacheDir = ""
  var isStop = false
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdLongOption:
      if p.key.cmpIgnoreStyle("passNim") == 0:
        passNim = p.val
      elif p.key.cmpIgnoreStyle("out") == 0:
        outFile = p.val
      elif p.key.cmpIgnoreStyle("nim") == 0:
        nimBinary = p.val
      elif p.key.cmpIgnoreStyle("nimcache") == 0:
        nimcacheDir = p.val
      else:
        echo "unexpected option: ", p.key
        isStop = true

    of cmdShortOption:
      if p.key == "o":
        outFile = p.val
      else:
        echo "unexpected option: ", p.key
        isStop = true
    of cmdArgument:
      src = p.key
      break

  if isStop:
    discard
  elif src.len == 0:
    echo helpText
  else:
    writeDepfile(src, DepOption(passNim: passNim, outFile: outFile,
                  nimBinary: nimBinary, nimcacheDir: nimcacheDir))

main()
