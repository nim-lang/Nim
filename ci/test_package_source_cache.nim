## Local Git integration tests. Pass the compiled cache helper as the only argument.

import std/[assertions, os, osproc, sequtils, streams, strtabs, strutils, tempfiles, uri]
import package_source_cache

type Fixture = object
  root, origin, url, cache, first, tool, realGit: string
  env, cached: Environment

proc git(t: Fixture, args: openArray[string], env: Environment = nil,
    check = true): tuple[output: string, code: int] =
  let env = if env == nil: t.env else: env
  let command = if env.hasKey("NIM_CI_GIT_SESSION"):
    env["NIM_CI_GIT_SESSION"] / "bin" / "git"
  else:
    t.realGit
  let process = startProcess(command, args = args, env = env, options = {poStdErrToStdOut})
  defer: process.close()
  result.output = process.outputStream.readAll()
  result.code = process.waitForExit()
  if check:
    doAssert result.code == 0, quoteShellCommand(args) & "\n" & result.output

proc repo(t: Fixture, name: string): string =
  result = t.root / name
  discard t.git(["init", "-b", "main", result])

proc commit(t: Fixture, repo, content: string): string =
  writeFile(repo / "value", content)
  discard t.git(["-C", repo, "add", "."])
  discard t.git(["-C", repo, "commit", "-m", content])
  t.git(["-C", repo, "rev-parse", "HEAD"]).output.strip()

proc session(t: Fixture, name: string, populate = true): Environment =
  let env = copyEnv(t.env)
  env["NIM_CI_GIT_POPULATE"] = $populate
  configure(t.cache, t.root / name, env, prefixes = ["file://"], tool = t.tool)

proc clone(t: Fixture, name: string, env: Environment = nil): string =
  result = t.root / name
  discard t.git(["clone", "--depth", "1", t.url, result], env = if env == nil: t.cached else: env)

proc mirror(t: Fixture, url = ""): string =
  mirrorPath(t.cache, if url.len == 0: t.url else: url)

proc initFixture(root, tool: string): Fixture =
  let localTool = root / "cache helper's binary"
  copyFileWithPermissions(tool, localTool)
  result = Fixture(root: root, tool: localTool, realGit: findExe("git"), env: environment())
  var keys: seq[string]
  for key in result.env.keys:
    if key.startsWith("GIT_") or key.startsWith("NIM_CI_GIT_"):
      keys.add(key)
  for key in keys:
    result.env.del(key)
  result.env["GIT_CONFIG_GLOBAL"] = root / "baseconfig"
  result.env["GIT_CONFIG_NOSYSTEM"] = "1"
  for role in ["AUTHOR", "COMMITTER"]:
    result.env["GIT_" & role & "_NAME"] = "Cache test"
    result.env["GIT_" & role & "_EMAIL"] = "cache@example.invalid"
  result.env["NIM_CI_GIT_POPULATE"] = "true"
  # file:// is enabled only for fixtures, never by CI setup.
  discard result.git(["config", "--global", "protocol.file.allow", "always"])
  result.origin = result.repo("upstream")
  result.first = result.commit(result.origin, "one")
  discard result.commit(result.origin, "two")
  discard result.git(["-C", result.origin, "tag", "v1.0.0", result.first])
  result.url = $Uri(scheme: "file", path: result.origin)
  result.cache = root / "cache"
  result.cached = result.session("first")

let args = commandLineParams()
doAssert args.len == 1, "pass the compiled package_source_cache executable"
let tool = absolutePath(args[0])
doAssert fileExists(tool), "cache helper does not exist: " & tool
var passed = 0

template test(name: untyped, body: untyped) =
  block:
    let root = createTempDir("nim package cache ", "")
    try:
      let t {.inject.} = initFixture(root, tool)
      body
      inc passed
      echo "PASS ", astToStr(name)
    finally:
      removeDir(root)

test shallowCloneFetchTagsAndCanonicalUrls:
  let dest = t.clone("clone with spaces")
  doAssert dirExists(t.mirror())
  doAssert t.git(["-C", dest, "rev-list", "--count", "HEAD"]).output.strip() == "1"
  for args in [@["remote", "get-url", "origin"], @["config", "remote.origin.url"]]:
    doAssert t.git(@["-C", dest] & args, env = t.cached).output.strip() == t.url
  discard t.git(["-C", dest, "fetch", "--depth", "1", "origin", "tag", "v1.0.0"], env = t.cached)
  discard t.git(["-C", dest, "checkout", "v1.0.0"], env = t.cached)
  doAssert t.git(["-C", dest, "rev-parse", "HEAD"]).output.strip() == t.first

test restoredCacheRefreshesHeadsTagsAndDefaultBranch:
  discard t.clone("old")
  discard t.git(["-C", t.origin, "checkout", "-b", "new-default"])
  let latest = t.commit(t.origin, "new head")
  discard t.git(["-C", t.origin, "tag", "v2.0.0"])
  let env = t.session("restored", populate = false)
  let dest = t.clone("fresh", env)
  doAssert t.git(["-C", dest, "rev-parse", "HEAD"]).output.strip() == latest
  doAssert t.git(["-C", dest, "branch", "--show-current"]).output.strip() == "new-default"
  doAssert "refs/tags/v2.0.0" in t.git(["ls-remote", t.url], env = env).output

test newRefAfterFirstAccessFallsBackUpstream:
  let dest = t.clone("clone")
  discard t.git(["-C", t.origin, "checkout", "--orphan", "new-ref"])
  let latest = t.commit(t.origin, "unseen commit")
  discard t.git(["-C", t.origin, "tag", "new-tag"])
  discard t.git(["-C", dest, "fetch", "--depth", "1", "origin", "new-ref"], env = t.cached)
  doAssert t.git(["-C", dest, "rev-parse", "FETCH_HEAD"]).output.strip() == latest
  doAssert latest in t.git(["ls-remote", t.url, "refs/tags/new-tag"], env = t.cached).output

test consumerCacheMissAndVersionDiscoveryUseUpstream:
  let env = t.session("consumer", populate = false)
  discard t.clone("miss", env)
  doAssert not dirExists(t.mirror())
  discard t.git(["ls-remote", "--tags", t.url], env = t.cached)
  doAssert not dirExists(t.mirror())

test invalidMirrorDoesNotBreakClone:
  createDir(t.mirror())
  writeFile(t.mirror() / "invalid", "bad cache entry")
  discard t.clone("fallback")

test mismatchedMirrorDoesNotBreakClone:
  discard t.clone("seed")
  discard t.git(["--git-dir", t.mirror(), "config", "remote.origin.url", "wrong-origin"])
  let env = t.session("mismatched")
  discard t.clone("fallback", env)

test symlinkMirrorDoesNotBreakClone:
  let target = t.repo("symlink target")
  discard t.commit(target, "keep")
  createDir(t.mirror().parentDir)
  createSymlink(target, t.mirror())
  discard t.clone("fallback")
  doAssert readFile(target / "value") == "keep"

test credentialBearingUrlsBypassMirrors:
  for url in ["https://user:secret@example.invalid/repo", "https://@example.invalid/repo"]:
    let process = startProcess(t.tool, args = @["remote", "origin", url],
      env = t.cached, options = {poStdErrToStdOut})
    process.inputStream.write("connect git-upload-pack\n")
    process.inputStream.close()
    let output = process.outputStream.readAll()
    let code = process.waitForExit()
    process.close()
    doAssert code != 0
    doAssert "credential-bearing URLs bypass the source cache" in output
    doAssert not dirExists(t.mirror(url))

test failedClonePreservesExistingDestination:
  let dest = t.root / "existing"
  createDir(dest)
  writeFile(dest / "keep", "unrelated work")
  let failed = t.git(["clone", "--recurse-submodules", "--", t.url, dest],
    env = t.cached, check = false)
  doAssert failed.code != 0
  doAssert readFile(dest / "keep") == "unrelated work"

test failedUpstreamIsNotHiddenByStaleCache:
  discard t.clone("seed")
  removeDir(t.origin)
  let env = t.session("offline", populate = false)
  doAssert t.git(["clone", "--depth", "1", t.url, t.root / "offline-clone"],
    env = env, check = false).code != 0

test relativeSubmoduleWithSpacesAndMissingMirror:
  let child = t.repo("child")
  let childUrl = $Uri(scheme: "file", path: child)
  discard t.commit(child, "child one")
  discard t.commit(child, "child two")
  discard t.git(["-C", t.origin, "submodule", "add", "../child", "sub dir"])
  discard t.git(["-C", t.origin, "commit", "-am", "add submodule"])
  let dest = t.clone("parent clone")
  discard t.git(["-C", dest, "submodule", "update", "--init", "--recursive", "--depth", "1"],
    env = t.cached)
  doAssert dirExists(t.mirror(childUrl))
  doAssert t.git(["-C", dest / "sub dir", "remote", "get-url", "origin"],
    env = t.cached).output.strip() == childUrl
  doAssert t.git(["-C", dest / "sub dir", "rev-list", "--count", "HEAD"]).output.strip() == "1"
  removeDir(t.mirror(childUrl))
  let env = t.session("submodule-miss", populate = false)
  let restored = t.clone("parent restored", env)
  discard t.git(["-C", restored, "submodule", "update", "--init", "--recursive"], env = env)
  doAssert not dirExists(t.mirror(childUrl))

test unsupportedRecursiveCloneUsesUpstream:
  discard t.git(["clone", "--recurse-submodules", t.url, t.root / "recursive"], env = t.cached)
  doAssert not dirExists(t.mirror())

test nimbleRecursiveCloneRetriesFailedSubmodule:
  let child = t.repo("recursive-child")
  discard t.commit(child, "submodule")
  discard t.git(["-C", t.origin, "submodule", "add", "../recursive-child", "sub dir"])
  discard t.git(["-C", t.origin, "commit", "-am", "add submodule"])
  let childUrl = $Uri(scheme: "file", path: child)
  let broken = t.mirror(childUrl)
  createDir(broken)
  writeFile(broken / "invalid", "")
  let dest = t.root / "nimble clone"
  let cloned = t.git(["clone", "--config", "core.autocrlf=false", "--config", "core.eol=lf",
    "--recurse-submodules", "--depth", "1", "--", t.url, dest], env = t.cached)
  doAssert "retrying the original command upstream" in cloned.output
  doAssert dirExists(t.mirror())
  doAssert fileExists(dest / "sub dir" / "value")
  doAssert t.git(["-C", dest, "remote", "get-url", "origin"],
    env = t.cached).output.strip() == t.url
  doAssert t.git(["-C", dest / "sub dir", "remote", "get-url", "origin"],
    env = t.cached).output.strip() == childUrl

test concurrentClonesShareOneMirror:
  var processes: seq[Process]
  try:
    for name in ["parallel-one", "parallel-two"]:
      processes.add(startProcess(t.cached["NIM_CI_GIT_SESSION"] / "bin" / "git",
        args = @["clone", "--depth", "1", t.url, t.root / name], env = t.cached,
        options = {poStdErrToStdOut}))
    for process in processes:
      let code = process.waitForExit(30_000)
      doAssert code != -1, "concurrent clone timed out"
      let output = process.outputStream.readAll()
      doAssert code == 0, output
    doAssert toSeq(walkDirs(t.cache / "repos" / "*.git")).len == 1
  finally:
    for process in processes:
      if process.running():
        process.terminate()
        discard process.waitForExit()
      process.close()

test actionsSetupPreservesGlobalConfigAndExportsEnvironment:
  let env = copyEnv(t.env)
  for key in ["GITHUB_ENV", "GITHUB_PATH", "GITHUB_OUTPUT"]:
    env[key] = t.root / key
  let process = startProcess(tool, args = @["setup", t.cache, t.root / "actions"],
    env = env, options = {poStdErrToStdOut})
  let output = process.outputStream.readAll()
  let code = process.waitForExit()
  process.close()
  doAssert code == 0, output
  for line in readFile(env["GITHUB_ENV"]).splitLines():
    if line.len > 0:
      let pair = line.split('=', 1)
      env[pair[0]] = pair[1]
  env["PATH"] = readFile(env["GITHUB_PATH"]).strip() & PathSep & env["PATH"]
  doAssert readFile(env["GITHUB_OUTPUT"]) == "populate=true\n"
  doAssert t.git(["config", "--global", "protocol.file.allow"],
    env = env).output.strip() == "always"
  doAssert t.git(["--version"], env = env).output == t.git(["--version"]).output

echo passed, " package source cache tests passed"
