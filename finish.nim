
# -------------- post unzip steps ---------------------------------------------

import strutils, os, osproc

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

  proc addToPathEnv(e: string) =
    let p = getUnicodeValue(r"Environment", "Path", HKEY_CURRENT_USER)
    let x = if e.contains(Whitespace): "\"" & e & "\"" else: e
    setUnicodeValue(r"Environment", "Path", p & ";" & x, HKEY_CURRENT_USER)

  proc createShortcut(src, dest: string; icon = "") =
    var cmd = "bin\\makelink.exe \"" & src & "\" \"\" \"" & dest &
         ".lnk\" \"\" 1 \"" & splitFile(src).dir & "\""
    if icon.len != 0:
      cmd.add " \"" & icon & "\" 0"
    discard execShellCmd(cmd)

  proc createStartMenuEntry() =
    let appdata = getEnv("APPDATA")
    if appdata.len == 0: return
    let dest = appdata & r"\Microsoft\Windows\Start Menu\Programs\Nim-" &
               NimVersion
    if dirExists(dest): return
    if askBool("Would like to add Nim-" & NimVersion &
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
                                                               poUsePath})
        when hostCPU == "i386":
          result = arch.startsWith("i686-")
        elif hostCPU == "amd64":
          result = arch.startsWith("x86_64-")
        else:
          {.error: "Unknown CPU for Windows.".}
      except OSError, IOError:
        result = false

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
      let y = expandFilename(if x[0] == '"' and x[^1] == '"':
                  substr(x, 1, x.len-2) else: x)
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
      let alternative = tryDirs(incompat, "dist/mingw", "../mingw", r"C:\mingw")
      if alternative.len == 0:
        if incompat.len > 0:
          echo "The following *incompatible* MingW installations exist"
          for x in incompat: echo x
        echo "No compatible MingW candidates found " &
             "in the standard locations [Error]"
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
