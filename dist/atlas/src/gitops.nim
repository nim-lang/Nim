import std/[os, osproc, strutils]
import context, osutils

type
  Command* = enum
    GitDiff = "git diff",
    GitTag = "git tag",
    GitTags = "git show-ref --tags",
    GitLastTaggedRef = "git rev-list --tags --max-count=1",
    GitDescribe = "git describe",
    GitRevParse = "git rev-parse",
    GitCheckout = "git checkout",
    GitPush = "git push origin",
    GitPull = "git pull",
    GitCurrentCommit = "git log -n 1 --format=%H"
    GitMergeBase = "git merge-base"

proc isGitDir*(path: string): bool = dirExists(path / ".git")

proc sameVersionAs*(tag, ver: string): bool =
  const VersionChars = {'0'..'9', '.'}

  proc safeCharAt(s: string; i: int): char {.inline.} =
    if i >= 0 and i < s.len: s[i] else: '\0'

  let idx = find(tag, ver)
  if idx >= 0:
    # we found the version as a substring inside the `tag`. But we
    # need to watch out the the boundaries are not part of a
    # larger/different version number:
    result = safeCharAt(tag, idx-1) notin VersionChars and
      safeCharAt(tag, idx+ver.len) notin VersionChars

proc extractVersion*(s: string): string =
  var i = 0
  while i < s.len and s[i] notin {'0'..'9'}: inc i
  result = s.substr(i)

proc exec*(c: var AtlasContext; cmd: Command; args: openArray[string]): (string, int) =
  when MockupRun:
    assert TestLog[c.step].cmd == cmd, $(TestLog[c.step].cmd, cmd, c.step)
    case cmd
    of GitDiff, GitTag, GitTags, GitLastTaggedRef, GitDescribe, GitRevParse, GitPush, GitPull, GitCurrentCommit:
      result = (TestLog[c.step].output, TestLog[c.step].exitCode)
    of GitCheckout:
      assert args[0] == TestLog[c.step].output
    of GitMergeBase:
      let tmp = TestLog[c.step].output.splitLines()
      assert tmp.len == 4, $tmp.len
      assert tmp[0] == args[0]
      assert tmp[1] == args[1]
      assert tmp[3] == ""
      result[0] = tmp[2]
      result[1] = TestLog[c.step].exitCode
    inc c.step
  else:
    result = silentExec($cmd, args)
    when ProduceTest:
      echo "cmd ", cmd, " args ", args, " --> ", result

proc isCleanGit*(c: var AtlasContext): string =
  result = ""
  let (outp, status) = exec(c, GitDiff, [])
  if outp.len != 0:
    result = "'git diff' not empty"
  elif status != 0:
    result = "'git diff' returned non-zero"

proc gitDescribeRefTag*(c: var AtlasContext; commit: string): string =
  let (lt, status) = exec(c, GitDescribe, ["--tags", commit])
  result = if status == 0: strutils.strip(lt) else: ""

proc getLastTaggedCommit*(c: var AtlasContext): string =
  let (ltr, status) = exec(c, GitLastTaggedRef, [])
  if status == 0:
    let lastTaggedRef = ltr.strip()
    let lastTag = gitDescribeRefTag(c, lastTaggedRef)
    if lastTag.len != 0:
      result = lastTag

proc collectTaggedVersions*(c: var AtlasContext): seq[(string, Version)] =
  let (outp, status) = exec(c, GitTags, [])
  if status == 0:
    result = parseTaggedVersions(outp)
  else:
    result = @[]

proc versionToCommit*(c: var AtlasContext; d: Dependency): string =
  let allVersions = collectTaggedVersions(c)
  case d.algo
  of MinVer:
    result = selectBestCommitMinVer(allVersions, d.query)
  of SemVer:
    result = selectBestCommitSemVer(allVersions, d.query)
  of MaxVer:
    result = selectBestCommitMaxVer(allVersions, d.query)

proc shortToCommit*(c: var AtlasContext; short: string): string =
  let (cc, status) = exec(c, GitRevParse, [short])
  result = if status == 0: strutils.strip(cc) else: ""

proc checkoutGitCommit*(c: var AtlasContext; p: PackageName; commit: string) =
  let (_, status) = exec(c, GitCheckout, [commit])
  if status != 0:
    error(c, p, "could not checkout commit " & commit)

proc gitPull*(c: var AtlasContext; p: PackageName) =
  let (_, status) = exec(c, GitPull, [])
  if status != 0:
    error(c, p, "could not 'git pull'")

proc gitTag*(c: var AtlasContext; tag: string) =
  let (_, status) = exec(c, GitTag, [tag])
  if status != 0:
    error(c, c.projectDir.PackageName, "could not 'git tag " & tag & "'")

proc pushTag*(c: var AtlasContext; tag: string) =
  let (outp, status) = exec(c, GitPush, [tag])
  if status != 0:
    error(c, c.projectDir.PackageName, "could not 'git push " & tag & "'")
  elif outp.strip() == "Everything up-to-date":
    info(c, c.projectDir.PackageName, "is up-to-date")
  else:
    info(c, c.projectDir.PackageName, "successfully pushed tag: " & tag)

proc incrementTag*(c: var AtlasContext; lastTag: string; field: Natural): string =
  var startPos =
    if lastTag[0] in {'0'..'9'}: 0
    else: 1
  var endPos = lastTag.find('.', startPos)
  if field >= 1:
    for i in 1 .. field:
      if endPos == -1:
        error c, projectFromCurrentDir(), "the last tag '" & lastTag & "' is missing . periods"
        return ""
      startPos = endPos + 1
      endPos = lastTag.find('.', startPos)
  if endPos == -1:
    endPos = len(lastTag)
  let patchNumber = parseInt(lastTag[startPos..<endPos])
  lastTag[0..<startPos] & $(patchNumber + 1) & lastTag[endPos..^1]

proc incrementLastTag*(c: var AtlasContext; field: Natural): string =
  let (ltr, status) = exec(c, GitLastTaggedRef, [])
  if status == 0:
    let
      lastTaggedRef = ltr.strip()
      lastTag = gitDescribeRefTag(c, lastTaggedRef)
      currentCommit = exec(c, GitCurrentCommit, [])[0].strip()

    if lastTaggedRef == currentCommit:
      info c, c.projectDir.PackageName, "the current commit '" & currentCommit & "' is already tagged '" & lastTag & "'"
      lastTag
    else:
      incrementTag(c, lastTag, field)
  else: "v0.0.1" # assuming no tags have been made yet

proc needsCommitLookup*(commit: string): bool {.inline.} =
  '.' in commit or commit == InvalidCommit

proc isShortCommitHash*(commit: string): bool {.inline.} =
  commit.len >= 4 and commit.len < 40

proc getRequiredCommit*(c: var AtlasContext; w: Dependency): string =
  if needsCommitLookup(w.commit): versionToCommit(c, w)
  elif isShortCommitHash(w.commit): shortToCommit(c, w.commit)
  else: w.commit

proc getRemoteUrl*(): PackageUrl =
  execProcess("git config --get remote.origin.url").strip().getUrl()

proc getCurrentCommit*(): string =
  result = execProcess("git log -1 --pretty=format:%H").strip()

proc isOutdated*(c: var AtlasContext; f: string): bool =
  ## determine if the given git repo `f` is updateable
  ##
  let (outp, status) = silentExec("git fetch", [])
  if status == 0:
    let (cc, status) = exec(c, GitLastTaggedRef, [])
    let latestVersion = strutils.strip(cc)
    if status == 0 and latestVersion.len > 0:
      # see if we're past that commit:
      let (cc, status) = exec(c, GitCurrentCommit, [])
      if status == 0:
        let currentCommit = strutils.strip(cc)
        if currentCommit != latestVersion:
          # checkout the later commit:
          # git merge-base --is-ancestor <commit> <commit>
          let (cc, status) = exec(c, GitMergeBase, [currentCommit, latestVersion])
          let mergeBase = strutils.strip(cc)
          #if mergeBase != latestVersion:
          #  echo f, " I'm at ", currentCommit, " release is at ", latestVersion, " merge base is ", mergeBase
          if status == 0 and mergeBase == currentCommit:
            let v = extractVersion gitDescribeRefTag(c, latestVersion)
            if v.len > 0:
              info c, toName(f), "new version available: " & v
              result = true
  else:
    warn c, toName(f), "`git fetch` failed: " & outp

proc updateDir*(c: var AtlasContext; file, filter: string) =
  withDir c, file:
    let pkg = PackageName(file)
    let (remote, _) = osproc.execCmdEx("git remote -v")
    if filter.len == 0 or filter in remote:
      let diff = isCleanGit(c)
      if diff != "":
        warn(c, pkg, "has uncommitted changes; skipped")
      else:
        let (branch, _) = osproc.execCmdEx("git rev-parse --abbrev-ref HEAD")
        if branch.strip.len > 0:
          let (output, exitCode) = osproc.execCmdEx("git pull origin " & branch.strip)
          if exitCode != 0:
            error c, pkg, output
          else:
            info(c, pkg, "successfully updated")
        else:
          error c, pkg, "could not fetch current branch name"
