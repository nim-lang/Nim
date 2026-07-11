import std/[os, syncio]
import artifacts, bifexports

proc writeFileStable(path, content: string) =
  let previous =
    try: readFile(path)
    except IOError: ""
  if previous != content:
    writeFile(path, content)

if paramCount() != 5:
  quit "usage: generate NIMCACHE SOURCE LIBRARY_NAME API_NAME OUTPUT_DIR"

let
  bifPath = findSemanticBif(paramStr(1), paramStr(2))
  libraryName = paramStr(3)
  apiName = paramStr(4)
  outputDir = paramStr(5)
  exports = readDynlibExports(bifPath)
  generated = generateDynlibArtifacts(exports, apiName, libraryName)

createDir(outputDir)
writeFileStable(outputDir / (apiName & ".h"), generated.cHeader)
writeFileStable(outputDir / (apiName & "_dynlib.nim"), generated.nimModule)
