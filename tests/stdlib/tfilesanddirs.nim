import std/[paths, files, dirs, appdirs]

from stdtest/specialpaths import buildDir
import std/[syncio, assertions]

block fileOperations:
  let files = @[Path"these.txt", Path"are.x", Path"testing.r", Path"files.q"]
  let dirs = @[Path"some", Path"created", Path"test", Path"dirs"]

  let dname = Path"__really_obscure_dir_name"

  createDir(dname.Path)
  doAssert dirExists(Path(dname))
 
  # Test creating files and dirs
  for dir in dirs:
    createDir(Path(dname/dir))
    doAssert dirExists(Path(dname/dir))

  for file in files:
    let fh = open(string(dname/file), fmReadWrite) # createFile
    fh.close()
    doAssert fileExists(Path(dname/file))

block: # getCacheDir
  doAssert getCacheDir().dirExists

block: # moveFile
  let tempDir = getTempDir() / Path("D20221022T151608")
  createDir(tempDir)
  defer: removeDir(tempDir)

block: # moveDir
  let tempDir = getTempDir() / Path("D20220609T161443")
  createDir(tempDir)
  defer: removeDir(tempDir)
