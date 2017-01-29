
# -------------- post unzip steps ---------------------------------------------

import strutils, os, osproc, browsers

const arch = $(sizeof(int)*8)

proc downloadMingw() =
  openDefaultBrowser("http://nim-lang.org/download/mingw$1.zip" % arch)

when defined(windows):
  import registry

  proc askBool(m: string): bool =
    stdout.write m
    while true:
      let answer = stdin.readLine().normalize
      case answer
      of "y", "yes":
        return true
      of "n", "no":
        return false
      else:
        echo "Please type 'y' or 'n'"

  proc askNumber(m: string; a, b: int): int =
    stdout.write m
    stdout.write " [" & $a & ".." & $b & "] "
    while true:
      let answer = stdin.readLine()
      try:
        result = parseInt answer
        if result < a or result > b:
          raise newException(ValueError, "number out of range")
        break
      except ValueError:
        echo "Please type in a number between ", a, " and ", b

  proc patchConfig(mingw: string) =
    const
      cfgFile = "config/nim.cfg"
      lookFor = """#gcc.path = r"$nim\dist\mingw\bin""""
      replacePattern = """gcc.path = r"$1""""
    try:
      let cfg = readFile(cfgFile)
      let newCfg = cfg.replace(lookFor, replacePattern % mingw)
      if newCfg == cfg:
        echo "Could not patch 'config/nim.cfg' [Error]"
        echo "Reason: patch substring not found:"
        echo lookFor
      else:
        writeFile(cfgFile, newCfg)
    except IOError:
      echo "Could not access 'config/nim.cfg' [Error]"

  proc addToPathEnv*(e: string) =
    let p = getUnicodeValue(r"Environment", "Path", HKEY_CURRENT_USER)
    let x = if e.contains(Whitespace): "\"" & e & "\"" else: e
    setUnicodeValue(r"Environment", "Path", p & ";" & x, HKEY_CURRENT_USER)

  proc createShortcut(src, dest: string; icon = "") =
    var cmd = "bin\\makelink.exe \"" & src & "\" \"\" \"" & dest &
         ".lnk\" \"\" 1 \"" & splitFile(src).dir & "\""
    if icon.len != 0:
      cmd.add " \"" & icon & "\" 0"
    discard execShellCmd(cmd)

  proc createStartMenuEntry*(override = false) =
    let appdata = getEnv("APPDATA")
    if appdata.len == 0: return
    let dest = appdata & r"\Microsoft\Windows\Start Menu\Programs\Nim-" &
               NimVersion
    if dirExists(dest): return
    if override or askBool("Would like to add Nim-" & NimVersion &
               " to your start menu? (y/n) "):
      createDir(dest)
      createShortcut(getCurrentDir() / "tools" / "start.bat", dest / "Nim",
                     getCurrentDir() / r"icons\nim.ico")
      if fileExists("doc/overview.html"):
        createShortcut(getCurrentDir() / "doc" / "html" / "overview.html",
                       dest / "Overview")
      if dirExists(r"dist\aporia-0.4.0"):
        createShortcut(getCurrentDir() / r"dist\aporia-0.4.0\bin\aporia.exe",
                       dest / "Aporia")

  proc checkGccArch(mingw: string): bool =
    let gccExe = mingw / r"gcc.exe"
    if fileExists(gccExe):
      try:
        let arch = execProcess(gccExe, ["-dumpmachine"], nil, {poStdErrToStdOut,
                                                               poUsePath}).strip
        when hostCPU == "i386":
          result = (arch.contains("i686-") and not arch.contains("w64")) or
                    arch == "mingw32"
        elif hostCPU == "amd64":
          result = arch.contains("x86_64-") or arch.contains("i686-w64-mingw32")
        else:
          {.error: "Unknown CPU for Windows.".}
      except OSError, IOError:
        result = false

  proc defaultMingwLocations(): seq[string] =
    proc probeDir(dir: string; result: var seq[string]) =
      for k, x in walkDir(dir, relative=true):
        if k in {pcDir, pcLinkToDir}:
          if x.contains("mingw") or x.contains("posix"):
            let dest = dir / x
            probeDir(dest, result)
            result.add(dest)

    result = @["dist/mingw", "../mingw", r"C:\mingw"]
    let pfx86 = getEnv("programfiles(x86)")
    let pf = getEnv("programfiles")
    when hostCPU == "i386":
      probeDir(pfx86, result)
      probeDir(pf, result)
    else:
      probeDir(pf, result)
      probeDir(pfx86, result)

  proc tryDirs(incompat: var seq[string]; dirs: varargs[string]): string =
    let bits = $(sizeof(pointer)*8)
    for d in dirs:
      if dirExists d:
        let x = expandFilename(d / "bin")
        if checkGccArch(x): return x
        else: incompat.add x
      elif dirExists(d & bits):
        let x = expandFilename((d & bits) / "bin")
        if checkGccArch(x): return x
        else: incompat.add x

proc main() =
  when defined(windows):
    let desiredPath = expandFilename(getCurrentDir() / "bin")
    let p = getUnicodeValue(r"Environment", "Path",
      HKEY_CURRENT_USER)
    var alreadyInPath = false
    var mingWchoices: seq[string] = @[]
    var incompat: seq[string] = @[]
    for x in p.split(';'):
      if x.len == 0: continue
      let y = try: expandFilename(if x[0] == '"' and x[^1] == '"':
                                    substr(x, 1, x.len-2) else: x)
              except: ""
      if y == desiredPath: alreadyInPath = true
      if y.toLowerAscii.contains("mingw"):
        if dirExists(y):
          if checkGccArch(y): mingWchoices.add y
          else: incompat.add y

    if alreadyInPath:
      echo "bin/nim.exe is already in your PATH [Skipping]"
    else:
      if askBool("nim.exe is not in your PATH environment variable.\n" &
          "Should it be added permanently? (y/n) "):
        addToPathEnv(desiredPath)
    if mingWchoices.len == 0:
      # No mingw in path, so try a few locations:
      let alternative = tryDirs(incompat, defaultMingwLocations())
      if alternative.len == 0:
        if incompat.len > 0:
          echo "The following *incompatible* MingW installations exist"
          for x in incompat: echo x
          echo "*incompatible* means Nim and GCC disagree on the size of a pointer."
        echo "No compatible MingW candidates found " &
             "in the standard locations [Error]"
        if askBool("Do you want to download MingW from Nim's website? (y/n) "):
          let dest = getCurrentDir() / "dist"
          downloadMingw()
          echo "After download, unzip it in: ", dest
          echo "so that ", dest / "mingw" & arch, " exists."
          if askBool("Download and unzip successful? (y/n) "):
            incompat.setLen 0
            let alternative = tryDirs(incompat, defaultMingwLocations())
            if alternative.len == 0:
              if incompat.len > 0:
                echo "The following *incompatible* MingW installations exist"
                for x in incompat: echo x
                echo "*incompatible* means Nim and GCC disagree on the size of a pointer."
              echo "Still no compatible MingW candidates found " &
                   "in the standard locations [Error]"
            else:
              echo "Patching Nim's config to use:"
              echo alternative
              patchConfig(alternative)
      else:
        if askBool("Found a MingW directory that is not in your PATH.\n" &
                   alternative &
                   "\nShould it be added to your PATH permanently? (y/n) "):
          addToPathEnv(alternative)
        elif askBool("Do you want to patch Nim's config to use this? (y/n) "):
          patchConfig(alternative)
    elif mingWchoices.len == 1:
      if askBool("MingW installation found at " & mingWchoices[0] & "\n" &
         "Do you want to patch Nim's config to use this?\n" &
         "(Not required since it's in your PATH!) (y/n) "):
        patchConfig(mingWchoices[0])
    else:
      echo "Multiple MingW installations found: "
      for i in 0..high(mingWchoices):
        echo "[", i, "] ", mingWchoices[i]
      if askBool("Do you want to patch Nim's config to use one of these? (y/n) "):
        let idx = askNumber("Which one do you want to use for Nim? ",
            1, len(mingWchoices))
        patchConfig(mingWchoices[idx-1])
    createStartMenuEntry()
  else:
    echo("Add ", getCurrentDir(), "/bin to your PATH...")

when isMainModule:
  main()
