import nake
import httpclient, zip/zipfiles, times, random, sequtils
nakeImports

randomize()

const
  GameAssets = "http://dl.dropbox.com/u/37533467/data-08-01-2012.7z"
  BinLibs = "http://dl.dropbox.com/u/37533467/libs-2012-09-12.zip"
  ExeName = "keineschweine"
  ServerDefines = "-d:NoSFML -d:NoChipmunk"
  TestBuildDefines = "-d:escapeMenuTest -d:debugWeps -d:showFPS -d:moreNim -d:debugKeys -d:foo -d:recordMode --forceBuild"
  ReleaseDefines = "-d:release"
  ReleaseTestDefines = "-d:debugWeps -d:debugKeys --forceBuild"

task "testprofile", "..":
  if shell("nim", TestBuildDefines, "--profiler:on", "--stacktrace:on", "compile", ExeName) == 0:
    shell "."/ExeName, "offline"

task "test", "Build with test defines":
  if shell("nim", TestBuildDefines, "compile", ExeName) != 0:
    quit "The build failed."

task "testrun", "Build with test defines and run":
  runTask "test"
  shell "."/ExeName

task "test2", "Build release test build test release build":
  if shell("nim", ReleaseDefines, ReleaseTestDefines, "compile", ExeName) == 0:
    shell "."/ExeName

when false:
  task "dirserver", "build the directory server":
    withDir "server":
      if shell("nim", ServerDefines, "compile", "dirserver") != 0:
        echo "Failed to build the dirserver"
        quit 1

task "zoneserver", "build the zone server":
  withDir "enet_server":
    if shell("nim", ServerDefines, "compile", "enet_server") != 0:
      quit "Failed to build the zoneserver"
task "zoneserver-gui", "build the zone server, with gui!":
  withDir "enet_server":
    if shell("nim", ServerDefines, "--app:gui", "compile", "enet_server") != 0:
      quit "Failed to build the zoneserver"

task "servers", "build the server and directory server":
  #runTask "dirserver"
  runTask "zoneserver"
  echo "Successfully built both servers :')"

task "all", "run SERVERS and TEST tasks":
  runTask "servers"
  runTask "test"

task "release", "release build":
  let res = shell("nim", ReleaseDefines, "compile", ExeName)
  if res != 0:
    echo "The build failed."
    quit 1
  else:
    runTask "clean"
    ## zip up all the files and such or something useful here

task "testskel", "create skeleton test dir for testing":
  let dirname = "test-" & $rand(5000)
  removeDir dirName
  createDir dirName/"data/fnt"
  copyFile "data/fnt/LiberationMono-Regular", dirName/"data/fnt/LiberationMono-Regular.ttf"
  copyFile "client_settings.json", dirName/"client_settings.json"
  runTask "test"
  copyFile ExeName, dirName/ExeName
  withDir dirName:
    shell "."/ExeName


task "clean", "cleanup generated files":
  var dirs = @["nimcache", "server"/"nimcache"]
  dirs.apply(proc(x: var string) =
    if dirExists(x): removeDir(x))

task "download", "download game assets":
  var
    skipAssets = false
    path = expandFilename("data")
    client = newHttpClient()
  path.add DirSep
  path.add(extractFilename(GameAssets))
  if fileExists(path):
    echo "The file already exists\n",
      "[R]emove  [M]ove  [Q]uit  [S]kip    Source: ", GameAssets
    case stdin.readLine.toLowerAscii
    of "r":
      removeFile path
    of "m":
      moveFile path, path/../(extractFilename(GameAssets)&"-old")
    of "s":
      skipAssets = true
    else:
      quit 0
  else:
    echo "Downloading from ", GameAssets
  if not skipAssets:
    echo "Downloading to ", path
    client.downloadFile(GameAssets, path)
    echo "Download finished"

    let targetDir = parentDir(parentDir(path))
    when defined(linux):
      let z7 = findExe("7z")
      if z7 == "":
        echo "Could not find 7z"
      elif shell(z7, "t", path) != 0: ##note to self: make sure this is right
        echo "Bad download"
      else:
        echo "Unpacking..."
        shell(z7, "x", "-w[$1]" % targetDir, path)
    else:
      echo "I do not know how to unpack the data on this system. Perhaps you could ",
        "fill this part in?"

  echo "Download binary libs? Only libs for linux are available currently, enjoy the irony.\n",
    "[Y]es [N]o   Source: ", BinLibs
  case stdin.readline.toLowerAscii
  of "y", "yes":
    discard ## o_O
  else:
    return
  path = extractFilename(BinLibs)
  client.downloadFile(BinLibs, path)
  echo "Downloaded dem libs ", path
  when true: echo "Unpack it yourself, sorry."
  else:  ## this crashes, dunno why
    var
      z: TZipArchive
      destDir = getCurrentDir()/("unzip" & $rand(5000))
    if not z.open(path, fmRead):
      echo "Could not open zip, bad download?"
      return
    echo "Extracting to ", destDir
    createDir destDir
    #z.extractAll destDir
    for f in z.walkFiles():
      z.extractFile(f, destDir/f)
    z.close()
    echo "Extracted the libs dir. Copy the ones you need to this dir."

task "zip-lib", "zip up the libs dir":
  var z: ZipArchive
  if not z.open("libs-" & getDateStr() & ".zip", fmReadWrite):
    quit "Could not open zip"
  for file in walkDirRec("libs", {pcFile, pcDir}):
    echo "adding file ", file
    z.addFile(file)
  z.close()
  echo "Great success!"
