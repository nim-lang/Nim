discard """
  targets: "c cpp"
  joinable: false
"""

import std/[compilesettings, os, osproc, tempfiles]

const
  nim = getCurrentCompilerExe()
  backend = querySetting(SingleValueSetting.backend)
  libpath = querySetting(libPath)
  source = staticRead("municode_module.nim")

block:
  # Keep archive filenames ASCII while still testing a Unicode module name.
  let dir = createTempDir("nim_unicode_module_", "")
  try:
    let file = dir / "åäö.nim"
    writeFile(file, source)
    let args = [nim, backend, "-r", "--hints:off", "--lib:" & libpath,
      "--nimcache:" & (dir / "nimcache"),
      "--out:" & (dir / "test".addFileExt(ExeExt)), file]
    let run = execCmdEx(quoteShellCommand(args))
    doAssert run.exitCode == 0, run.output
  finally:
    removeDir(dir)
