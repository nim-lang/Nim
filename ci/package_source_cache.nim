## Optional, source-only Git cache for package CI. Git's remote-helper protocol
## serves local bare mirrors through upload-pack, including shallow fetches.

import std/[algorithm, os, osproc, sequtils, strtabs, strutils, uri]
import std/posix
# Keep the bootstrap tool independent of Nimble packages.
{.push warning[Deprecated]: off.}
import std/sha1
{.pop.}

const prefixes = ["https://", "http://", "git://", "ssh://", "git@"]

type Environment* = StringTableRef

proc environment*(): Environment =
  result = newStringTable(modeCaseSensitive)
  for key, value in envPairs():
    result[key] = value

proc copyEnv*(env: Environment): Environment =
  result = newStringTable(modeCaseSensitive)
  for key, value in env:
    result[key] = value

proc upstreamEnv(env: Environment): Environment =
  result = copyEnv(env)
  result["GIT_CONFIG_GLOBAL"] = env["NIM_CI_GIT_BASE_CONFIG"]
  result["NIM_CI_GIT_BYPASS"] = "1"

proc execGit(args: seq[string], env: Environment) {.noreturn.} =
  let argv = allocCStringArray(@[env["NIM_CI_REAL_GIT"]] & args)
  var entries: seq[string]
  for key, value in env:
    entries.add(key & "=" & value)
  let envp = allocCStringArray(entries)
  discard execve(env["NIM_CI_REAL_GIT"].cstring, argv, envp)
  let error = osLastError()
  deallocCStringArray(argv)
  deallocCStringArray(envp)
  raiseOSError(error)

proc callGit(args: seq[string], env: Environment): int =
  let process = startProcess(env["NIM_CI_REAL_GIT"], args = args, env = env,
    options = {poParentStreams})
  defer: process.close()
  process.waitForExit()

proc captureGit(args: seq[string], env: Environment): tuple[output: string, code: int] =
  # osproc pipes stderr separately when capturing stdout. Inherit stderr here
  # instead: diagnostics must never contaminate remote-helper protocol output.
  var descriptors: array[2, cint]
  if pipe(descriptors) != 0:
    raiseOSError(osLastError())
  let pid = fork()
  if pid < 0:
    let error = osLastError()
    discard posix.close(descriptors[0])
    discard posix.close(descriptors[1])
    raiseOSError(error)
  if pid == 0:
    discard posix.close(descriptors[0])
    if dup2(descriptors[1], STDOUT_FILENO) < 0:
      exitnow(1)
    discard posix.close(descriptors[1])
    try:
      execGit(args, env)
    except OSError:
      exitnow(1)
  discard posix.close(descriptors[1])
  defer: discard posix.close(descriptors[0])
  var buffer: array[4096, char]
  var readError: OSErrorCode
  while true:
    let count = posix.read(descriptors[0], addr buffer[0], buffer.len)
    if count > 0:
      let offset = result.output.len
      result.output.setLen(offset + count)
      copyMem(addr result.output[offset], addr buffer[0], count)
    elif count == 0:
      break
    elif errno != EINTR:
      readError = osLastError()
      break
  var status: cint
  while waitpid(pid, status, 0) < 0:
    if errno != EINTR:
      raiseOSError(osLastError())
  if readError != OSErrorCode(0):
    raiseOSError(readError)
  result.code = if WIFEXITED(status): int(WEXITSTATUS(status)) else: 1

proc runGit(env: Environment, args: varargs[string]): string =
  let captured = captureGit(@args, upstreamEnv(env))
  if captured.code != 0:
    raise newException(IOError, "Git failed: " & quoteShellCommand(args))
  captured.output

proc mirrorPath*(cache, url: string): string =
  # A stable, dependency-free filename; the stored origin is checked separately.
  cache / "repos" / (($secureHash(url)).toLowerAscii & ".git")

proc flock(fd, operation: cint): cint {.importc, header: "<sys/file.h>".}
var lockExclusive {.importc: "LOCK_EX", header: "<sys/file.h>".}: cint

proc mirrorFor(url: string, env: Environment): string =
  let parsed = parseUri(url)
  # Reject userinfo, including an empty username (https://@host).
  if parsed.scheme in ["http", "https"] and '@' in url.split("://", 1)[1].split('/')[0]:
    raise newException(ValueError, "credential-bearing URLs bypass the source cache")
  result = mirrorPath(env["NIM_CI_GIT_CACHE"], url)
  let key = result.extractFilename.changeFileExt("")
  let session = env["NIM_CI_GIT_SESSION"]
  let checked = session / "checked" / key
  createDir(session / "locks")
  let lock = open(session / "locks" / key, fmAppend)
  defer: lock.close()
  # Do not let upload-pack or Git subprocesses keep the lock alive.
  if not lock.getFileHandle().setInheritable(false):
    raiseOSError(osLastError())
  while flock(lock.getFileHandle(), lockExclusive) != 0:
    if errno != EINTR:
      raiseOSError(osLastError())
  if symlinkExists(result):
    raise newException(ValueError, "source cache contains a repository symlink")
  if fileExists(checked) and dirExists(result):
    return
  if dirExists(result) or fileExists(result):
    let bare = runGit(env, "--git-dir", result, "rev-parse", "--is-bare-repository").strip()
    let origin = runGit(env, "--git-dir", result, "config", "remote.origin.url").strip()
    if bare != "true" or origin != url:
      raise newException(ValueError, "source cache repository does not match its URL")
    discard runGit(env, "--git-dir", result, "fetch", "--prune", "origin")
  else:
    if env.getOrDefault("NIM_CI_GIT_POPULATE") != "true":
      raise newException(ValueError, "repository is not in the source cache")
    createDir(result.parentDir)
    let staging = result & ".staging-" & $getCurrentProcessId()
    try:
      discard runGit(env, "clone", "--mirror", url, staging)
      moveDir(staging, result)
    finally:
      if dirExists(staging):
        removeDir(staging)
  # A restored repository may have changed its default branch.
  for line in runGit(env, "ls-remote", "--symref", url, "HEAD").splitLines():
    if line.startsWith("ref: ") and line.endsWith("\tHEAD"):
      discard runGit(env, "--git-dir", result, "symbolic-ref", "HEAD", line[5..^1].split('\t')[0])
      break
  createDir(checked.parentDir)
  writeFile(checked, "")

proc remote(args: seq[string], env: Environment): int =
  if args.len != 2:
    raise newException(ValueError, "Git remote helper requires a remote name and URL")
  # Read one byte at a time. Buffered stdin could swallow the protocol packets
  # that upload-pack must read after the connect response.
  while true:
    var line: string
    var ch: char
    while true:
      let count = posix.read(STDIN_FILENO, addr ch, 1)
      if count < 0:
        if errno != EINTR:
          raiseOSError(osLastError())
      elif count == 0 or ch == '\n':
        break
      else:
        line.add(ch)
    if line.len == 0:
      return 0
    case line
    of "capabilities": stdout.write("connect\n\n")
    of "connect git-upload-pack":
      let mirror = mirrorFor(args[1], env)
      stdout.write("\n")
      stdout.flushFile()
      execGit(@["upload-pack", mirror], upstreamEnv(env))
    else:
      if line.startsWith("option "):
        stdout.write("unsupported\n")
      else:
        raise newException(ValueError, "unsupported source-cache request: " & line)
    stdout.flushFile()

proc commandIndex(args: seq[string]): int =
  while result < args.len:
    let arg = args[result]
    if arg in ["-C", "-c", "--git-dir", "--work-tree", "--namespace"]:
      result += 2
    elif arg.startsWith("-"):
      inc result
    else:
      return

proc git(args: seq[string], env: Environment): int =
  let index = commandIndex(args)
  let command = if index < args.len: args[index] else: ""
  let rest = if index < args.len: args[index + 1..^1] else: @[]
  let upstream = upstreamEnv(env)
  if env.getOrDefault("NIM_CI_GIT_BYPASS") == "1":
    execGit(args, upstream)
  if command == "clone" and
      rest.anyIt(it == "--recursive" or it.startsWith("--recurse-submodules")):
    # Nimble supplies "-- URL DIRECTORY". Split only this known clone form so
    # failed submodules can retry without deleting their parent checkout.
    let separator = rest.find("--")
    const unsupported = ["--bare", "--mirror", "--no-checkout", "-n", "--shallow-submodules",
      "--remote-submodules", "--also-filter-submodules"]
    if separator < 0 or rest.len - separator != 3 or
        rest[0..<separator].anyIt(it in unsupported or it.startsWith("--recurse-submodules=")):
      execGit(args, upstream)
    let leading = args[0..<index]
    let cloneArgs = rest[0..<separator].filterIt(it notin ["--recursive", "--recurse-submodules"])
    result = git(leading & @["clone"] & cloneArgs & rest[separator..^1], env)
    if result != 0:
      return
    discard runGit(env, leading & @["-C", rest[^1], "config", "--add", "submodule.active", "."])
    return git(leading & @["-C", rest[^1], "submodule", "update", "--init", "--recursive"], env)
  let network = command in ["clone", "fetch", "ls-remote", "submodule"] or
    (command == "remote" and rest.len > 0 and rest[0] == "update")
  if not network:
    execGit(args, upstream)
  if command == "ls-remote":
    let urls = rest.filterIt("://" in it or it.startsWith("git@"))
    if urls.len == 0 or not dirExists(mirrorPath(env["NIM_CI_GIT_CACHE"], urls[0])):
      execGit(args, upstream)
    let captured = captureGit(args, env)
    if captured.code == 0 and captured.output.len > 0:
      stdout.write(captured.output)
      return 0
    # Empty output may mean a tag appeared after first access this session.
    return callGit(args, upstream)
  result = callGit(args, env)
  if result != 0:
    stderr.writeLine("Git source cache: retrying the original command upstream")
    result = callGit(args, upstream)

proc configure*(cache, session: string, original: Environment,
    prefixes: openArray[string] = prefixes, tool = getAppFilename()): Environment =
  result = copyEnv(original)
  let cache = absolutePath(cache)
  let session = absolutePath(session)
  createDir(session)
  createDir(cache)
  let realGit = result.getOrDefault("NIM_CI_REAL_GIT", findExe("git"))
  if realGit.len == 0:
    raise newException(ValueError, "Git was not found")
  let base = absolutePath(result.getOrDefault("NIM_CI_GIT_BASE_CONFIG",
    result.getOrDefault("GIT_CONFIG_GLOBAL", getHomeDir() / ".gitconfig")))
  result["NIM_CI_REAL_GIT"] = realGit
  result["NIM_CI_GIT_BASE_CONFIG"] = base
  result["NIM_CI_GIT_CACHE"] = cache
  result["NIM_CI_GIT_SESSION"] = session
  if not result.hasKey("NIM_CI_GIT_POPULATE"):
    result["NIM_CI_GIT_POPULATE"] = "false"
  let config = session / "gitconfig"
  writeFile(config, "")
  if fileExists(base):
    discard runGit(result, "config", "--file", config, "include.path", base)
  discard runGit(result, "config", "--file", config, "protocol.nim-ci.allow", "always")
  var rewrites: seq[string]
  if result["NIM_CI_GIT_POPULATE"] == "true":
    rewrites = @prefixes
  else:
    # Consumers only rewrite URLs that already have a mirror.
    for mirror in toSeq(walkDirs(cache / "repos" / "*.git")).sorted():
      if not symlinkExists(mirror):
        try:
          let url = runGit(result, "--git-dir", mirror, "config", "remote.origin.url").strip()
          if prefixes.anyIt(url.startsWith(it)):
            rewrites.add(url)
        except IOError:
          discard
  for prefix in rewrites:
    discard runGit(result, "config", "--file", config, "--add",
      "url.nim-ci::" & prefix & ".insteadOf", prefix)
  let bindir = session / "bin"
  createDir(bindir)
  for (name, mode) in [("git", "git"), ("git-remote-nim-ci", "remote")]:
    let script = bindir / name
    writeFile(script, "#!/bin/sh\nexec " & quoteShell(tool) & " " & mode & " \"$@\"\n")
    setFilePermissions(script, {fpUserRead, fpUserWrite, fpUserExec, fpGroupRead,
      fpGroupExec, fpOthersRead, fpOthersExec})
  result["GIT_CONFIG_GLOBAL"] = config
  result["PATH"] = bindir & PathSep & result.getOrDefault("PATH")

proc appendFile(path, value: string) =
  let output = open(path, fmAppend)
  defer: output.close()
  output.write(value)

proc main(): int =
  let args = commandLineParams()
  let env = environment()
  if args.len == 0:
    raise newException(ValueError, "expected setup, git or remote")
  case args[0]
  of "setup":
    if args.len != 3:
      raise newException(ValueError,
        "setup requires a cache directory and a per-job session directory")
    let configured = configure(args[1], args[2], env)
    for key in ["NIM_CI_REAL_GIT", "NIM_CI_GIT_BASE_CONFIG", "NIM_CI_GIT_CACHE",
        "NIM_CI_GIT_SESSION", "NIM_CI_GIT_POPULATE", "GIT_CONFIG_GLOBAL"]:
      appendFile(env["GITHUB_ENV"], key & "=" & configured[key] & "\n")
    appendFile(env["GITHUB_PATH"], configured["NIM_CI_GIT_SESSION"] / "bin" & "\n")
    appendFile(env["GITHUB_OUTPUT"], "populate=" & configured["NIM_CI_GIT_POPULATE"] & "\n")
  of "git": result = git(args[1..^1], env)
  of "remote": result = remote(args[1..^1], env)
  else: raise newException(ValueError, "expected setup, git or remote")

when isMainModule:
  try:
    quit(main())
  except CatchableError as error:
    stderr.writeLine("Git source cache: " & error.msg)
    quit(1)
