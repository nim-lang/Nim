# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

## This module implements some operations which use version control system
## tools like Git and Mercurial on which Nimble depends.

import tables, strutils, strformat, os, sets
import common, paths, tools, sha1hashes

type
  VcsType* = enum
    ## Represents a marker for the type of VCS under which is some file system
    ## directory.
    vcsTypeNone = "none"
    vcsTypeGit  = "git"
    vcsTypeHg   = "hg"

  VcsTypeAndSpecialDirPath = tuple[vcsType: VcsType, path: Path]
    ## Represents a cache entry for the directory VCS type and VCS special
    ## directory path used by `getVcsTypeAndSpecialDirPath` procedure.
  
  BranchType* = enum
    ## Determines the branch type which to be queried.
    btLocal, btRemoteTracking, btBoth

  RemoteUrlType {.pure.} = enum
    ## Represents the type of URL of some VCS remote repository. Fetch URLs are
    ## for downloading data from the repository and push URLs are for uploading
    ## data to it.
    fetch, push

const
  noVcsSpecialDir    = ""
  gitSpecialDir      = ".git"
  hgSpecialDir       = ".hg"

  noVcsDefaultBranch = ""
  gitDefaultBranch   = "master"
  hgDefaultBranch    = "default"

  noVcsDefaultRemote = ""
  gitDefaultRemote   = "origin"
  hgDefaultRemote    = "default"

proc getVcsSpecialDir*(vcsType: VcsType): string =
  ## Returns a special dir for given VCS type or an empty string for
  ## `vcsTypeNone`.
  return case vcsType
    of vcsTypeNone: noVcsSpecialDir
    of vcsTypeGit:  gitSpecialDir
    of vcsTypeHg:   hgSpecialDir

proc getVcsDefaultBranchName*(vcsType: VcsType): string =
  ## Returns the name of the default branch for given VCS.
  return case vcsType
    of vcsTypeNone: noVcsDefaultBranch
    of vcsTypeGit:  gitDefaultBranch
    of vcsTypeHg:   hgDefaultBranch

proc getVcsDefaultRemoteName*(vcsType: VcsType): string =
  return case vcsType
    of vcsTypeNone: noVcsDefaultRemote
    of vcsTypeGit:  gitDefaultRemote
    of vcsTypeHg:   hgDefaultRemote

proc dirDoesNotExistErrorMsg(dir: Path): string  =
  &"The directory \"{dir}\" does not exist."

proc hasVcsSubDir*(dir: Path): VcsType =
  ## Checks whether a directory has a special subdirectory for some supported
  ## kind of VCS.
  if (dir / gitSpecialDir.Path).dirExists:
    result = vcsTypeGit
  elif (dir / hgSpecialDir.Path).dirExists:
    result = vcsTypeHg
  else:
    result = vcsTypeNone

proc getVcsTypeAndSpecialDirPath*(dir: Path): VcsTypeAndSpecialDirPath = 
  ## By given directory `dir` gets the type of VCS under which is it by
  ## traversing the parent directories until some specific directory like
  ## `.git`, `.hg` or the root of the file system is found. Additionally it
  ## returns the path to the VCS special directory if the directory `dir is
  ## under some supported VCS type.
  ##
  ## The procedure uses a in memory cache to bypass multiple checks for the same
  ## directory in single run of Nimble.
  ##
  ## Raises a `NimbleError` in the case the directory `dir` does not exist.

  var cache {.global.}: Table[Path, VcsTypeAndSpecialDirPath]
  if cache.hasKey(dir):
    return cache[dir]

  if not dir.dirExists:
    raise nimbleError(dirDoesNotExistErrorMsg(dir))

  var
    dirIter = dir
    vcsType = vcsTypeNone

  while not dirIter.isRootDir:
    vcsType = hasVcsSubDir(dirIter)
    if vcsType != vcsTypeNone:
      break
    dirIter = dirIter.parentDir

  if vcsType == vcsTypeNone:
    vcsType = hasVcsSubDir(dirIter)
  else:
    dirIter = dirIter / vcsType.getVcsSpecialDir.Path

  result = (vcsType, dirIter)
  cache[dir] = result

proc getVcsType*(dir: Path): VcsType =
  ## Returns VCS type of the given directory.
  ## Raises a `NimbleError` in the case the directory `dir` does not exist.
  dir.getVcsTypeAndSpecialDirPath.vcsType

proc git(path: Path): string =
  ## Returns string for Git call at specific path `path`.
  &"git -C {path.quoteShell}"

proc hg(path: Path): string =
  ## Returns string for Mercurial call at specific path `path`.
  &"hg --cwd {path.quoteShell}"

proc dirInNotUnderSourceControlErrorMsg*(dir: Path): string =
  &"The directory \"{dir}\" is not under source control."

template doVcsCmdImpl(dir: Path, gitCmd, hgCmd: string,
                      doCmd, noVcsAction: untyped): untyped =
  ## This is a helper template for executing Git or Mercurial external command
  ## `gitCmd` or `hgCmd` in the directory `dir` according to the type of version
  ## control applied to the directory via some procedure `doCmd` or executing
  ## some other action `noVcsAction` in the case it is not under some of the
  ## supported VCS types.

  case getVcsType(dir)
    of vcsTypeGit:
      `doCmd`(git(dir) & " " & gitCmd)
    of vcsTypeHg:
      `doCmd`(hg(dir) & " " & hgCmd)
    of vcsTypeNone:
      `noVcsAction`

template doVcsCmdImpl(dir: Path, gitCmd, hgCmd: string,
                      doCmd: untyped): untyped =
  ## This is a helper template for executing Git or Mercurial external command
  ## `gitCmd` or `hgCmd` in the directory `dir` according to the type of version
  ## control applied to the directory via some procedure `doCmd` or raising a
  ## `NimbleError` in the case it is not under some of the supported VCS types.

  doVcsCmdImpl(dir, gitCmd, hgCmd, doCmd):
    raise nimbleError(dirInNotUnderSourceControlErrorMsg(dir))

template doVcsCmd(dir: Path, gitCmd, hgCmd: string): untyped =
  ## This is a helper template for executing Git or Mercurial external command
  ## `gitCmd` or `hgCmd` in the directory `dir` according to the type of version
  ## control applied to the directory via `doCmdEx` procedure or raising a
  ## `NimbleError` in the case it is not under some of the supported VCS types.

  doVcsCmdImpl(dir, gitCmd, hgCmd): doCmdEx

template tryDoVcsCmd(dir: Path, gitCmd, hgCmd: string,
                     noVcsAction: untyped): untyped =
  ## This is a helper template for executing Git or Mercurial external command
  ## `gitCmd` or `hgCmd` in the directory `dir` according to the type of version
  ## control applied to the directory via `tryDoCmdEx` procedure or executing
  ## some other action `noVcsAction` in the case it is not under some of the
  ## supported VCS types.

  doVcsCmdImpl(dir, gitCmd, hgCmd):
    tryDoCmdEx
  do:
    `noVcsAction`

template tryDoVcsCmd(dir: Path, gitCmd, hgCmd: string): untyped =
  ## This is a helper template for executing Git or Mercurial external command
  ## `gitCmd` or `hgCmd` in the directory `dir` according to the type of version
  ## control applied to the directory via `tryDoCmdEx` procedure or raising a
  ## `NimbleError` in the case it is not under some of the supported VCS types.

  doVcsCmdImpl(dir, gitCmd, hgCmd): tryDoCmdEx

proc getVcsRevision*(dir: Path): Sha1Hash =
  ## Returns current revision number if the directory `dir` is under version
  ## control, or an invalid Sha1 checksum otherwise.
  ##
  ## Raises a `NimbleError` if:
  ##   - the external command fails.
  ##   - the directory does not exist.
  ##   - there is no vcsRevisions in the repository.

  let vcsRevision = tryDoVcsCmd(dir,
    gitCmd = "rev-parse HEAD",
    hgCmd  = "id -i --debug",
    noVcsAction = $notSetSha1Hash)

  return initSha1Hash(vcsRevision.strip(chars = Whitespace + {'+'}))

proc getPackageFileListWithoutVcs(dir: Path): seq[string] =
  ## Recursively walks the directory `dir` and returns a list of files in it and
  ## its subdirectories.
  for file in walkDirRec($dir, yieldFilter = {pcFile, pcLinkToFile},
                         relative = true):
    when defined(windows):
      # On windows relative paths to files which are included in the calculation
      # of the package checksum must be the same as on POSIX systems.
      let file = file.replace('\\', '/')
    result.add file

proc getPackageFileList*(dir: Path): seq[string] =
  ## Retrieves a sequence of file names from the directory `dir` and its
  ## sub-directories by trying to get it from Git, Mercurial or directly from
  ## the file system if both fail.
  ##
  ## Raises a `NimbleError` if:
  ##   - the external command fails.
  ##   - the directory does not exist.

  const noVcsOutput = "/"

  let output = tryDoVcsCmd(dir,
    gitCmd = "ls-files",
    hgCmd  = "manifest",
    noVcsAction = noVcsOutput)

  return
    if output != noVcsOutput:
      output.strip.splitLines
    else:
      dir.getPackageFileListWithoutVcs

proc isWorkingCopyClean*(path: Path): bool =
  ## Checks whether a repository at path `path` has a clean working copy. Do
  ## not consider untracked and ignored files.
  ##
  ## Raises a `NimbleError` if:
  ##   - the external command fails.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type.

  let output = tryDoVcsCmd(path,
    gitCmd = "status --untracked-files=no --porcelain",
    hgCmd  = "status -q --color=off")
  return output.strip.len == 0

proc getRemotesNames*(path: Path): seq[string] =
  ## Retrieves a sequence with the names of the set remotes for the repository
  ## at path `path`.
  ##
  ## Raises a `NimbleError` if:
  ##   - the external command fails.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type.

  let output = tryDoVcsCmd(path,
    gitCmd = "remote",
    hgCmd  = "paths -q").strip

  if output.len > 0:
    result = output.splitLines

proc getRemoteUrl(path: Path, remoteName: string,
                  urlType: RemoteUrlType): string =
  ## Retrieves a fetch or push URL for the remote with name `remoteName` set in
  ## repository at path `repositoryPath`.
  ##
  ## Raises a `NimbleError` if:
  ##   - the external command fails.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type.
  
  let fetchOrPush = case urlType
    of RemoteUrlType.fetch: ""
    of RemoteUrlType.push: "--push"

  result = tryDoVcsCmd(path,
    gitCmd = &"remote get-url {fetchOrPush} {remoteName}",
    hgCmd  = &"paths {remoteName}")

  return result.strip

proc getRemoteFetchUrl*(path: Path, remoteName: string): string =
  ## Retrieves a fetch URL for the remote with name `remoteName` set in
  ## repository at path `repositoryPath`.
  ##
  ## Raises a `NimbleError` if:
  ##   - the external command fails.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type.
  getRemoteUrl(path, remoteName, RemoteUrlType.fetch)

proc getRemotePushUrl*(path: Path, remoteName: string): string =
  ## Retrieves a push URL for the remote with name `remoteName` set in
  ## repository at path `repositoryPath`.
  ##
  ## Raises a `NimbleError` if:
  ##   - the external command fails.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type.
  getRemoteUrl(path, remoteName, RemoteUrlType.push)

proc getRemotesPushUrls*(path: Path): seq[string] =
  ## Retrieves a sequence with the push URLs of the set remotes for the
  ## repository at path `path`.
  ## 
  ## Raises a `NimbleError` if:
  ##   - the external command fails.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type.

  let remotesNames = path.getRemotesNames
  result = newSeqOfCap[string](remotesNames.len)
  for remote in remotesNames:
    result.add getRemotePushUrl(path, remote)

proc isVcsRevisionPresentOnSomeRemote*(
    path: Path, vcsRevision: Sha1Hash): bool =
  ## Checks whether a VCS revision `vcsRevision` is present on some of the
  ## remotes of the repository at path `path`.
  ##
  ## Raises a `NimbleError` if:
  ##   - the external source control tool is not found.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type.

  # Note: When `--depth=1` is missing the git command returns success even the
  # revision is present only locally, but when it is present dispute being
  # `--dry-run` the code below for some reason corrupts the working copy of the
  # Git repository living it in a grafted state and for this reason another
  # solution must be found. It seems like a bug in Git.

  # for remotePushUrl in path.getRemotesPushUrls:
  #   let
  #     remotePushUrl = remotePushUrl.quoteShell
  #     (_, exitCode) = doVcsCmd(path,
  #       gitCmd = &"fetch {remotePushUrl} {vcsRevision} -q --dry-run",
  #       hgCmd  = &"pull {remotePushUrl} -r {vcsRevision} -q")
  #   if exitCode == QuitSuccess:
  #     return true

  let vcsType = path.getVcsType
  if vcsType == vcsTypeGit:
    for remotePushUrl in path.getRemotesPushUrls:
      let
        remotePushUrl = remotePushUrl.quoteShell
        (_, fetchCmdExitCode) = doCmdEx(&"{git(path)} fetch {remotePushUrl}")
      if fetchCmdExitCode == QuitFailure:
        continue

      let (branchCmdOutput, branchCmdExitCode) = doCmdEx(
        &"{git(path)} branch -r --contains {vcsRevision}")
      if branchCmdExitCode == QuitSuccess and branchCmdOutput.len > 0:
        return true
  elif vcsType == vcsTypeHg:
    for remotePushUrl in path.getRemotesPushUrls:
      let
        remotePushUrl = remotePushUrl.quoteShell
        (_, exitCode) = doCmdEx(
          &"{hg(path)} pull {remotePushUrl} -r {vcsRevision} -q")
      if exitCode == QuitSuccess:
        return true
  else:
    raise nimbleError(dirInNotUnderSourceControlErrorMsg(path))

proc getCurrentBranch*(path: Path): string =
  ## Get the name of the current branch for the VCS repository at path `path`.
  ## Returns an empty string in the case the repository is in a detached state.
  ##
  ## Raises a `NimbleError` if:
  ##   - the external command fails.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type.

  result = tryDoVcsCmd(path,
    gitCmd = "branch --show-current",
    hgCmd  = "branch")

  return result.strip

proc getBranchesOnWhichVcsRevisionIsPresent*(
    path: Path, vcsRevision: Sha1Hash, branchType = btBoth): HashSet[string] =
  ## Returns a set of the names of all branches which contain revision
  ## `vcsRevision` for a repository at path `path`. If the VCS system is Git
  ## `branchType` determines which branches to be returned: local branches,
  ## remote tracking branches or both. The parameter has no effect for
  ## Mercurial repositories.
  ## 
  ## Note: In Mercurial a revision is present always only on a single branch.
  ## For this reason we are searching for all branches where the revision is
  ## found as an ancestor of some revision of the branch.
  ## 
  ## Raises a `NimbleError` if:
  ##   - the external source control tool is not found.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type.

  let
    branchTypeParam = case branchType
      of btLocal: ""
      of btRemoteTracking: "-r"
      of btBoth: "-a"
    (output, errorCode) = doVcsCmd(path,
      gitCmd = &"branch {branchTypeParam} --no-color --contains {vcsRevision}",
      hgCmd  = &"log -r {vcsRevision}:: -T '{{branch}}\\n'")

  if errorCode != QuitSuccess or output.len == 0:
    # If the VCS revision is not found in any local branch Git exits with
    # failure, but Mercurial exits with success and an empty output. In both
    # cases we are returning an empty set.
    return

  let vcsType = path.getVcsType
  for line in output.strip.splitLines:
    var line = line.strip(chars = Whitespace + {'*', '\''})
    if vcsType == vcsTypeGit and branchType == btBoth:
      # For "git branch -a" remote branches are starting with "remotes" which
      # have to be removed for uniformity with "git branch -r".
      const prefix = "remotes/"
      if line.startsWith(prefix):
        line = line[prefix.len .. ^1]
    if line.len > 0:
      result.incl line

proc isVcsRevisionPresentOnSomeBranch*(path: Path, vcsRevision: Sha1Hash):
    bool =
  ## Checks whether a given VCS revision `vcsRevision` is found on any local
  ## branch of the repository at path `path`.
  ## 
  ## Raises a `NimbleError` if:
  ##   - the external source control tool is not found.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type

  getBranchesOnWhichVcsRevisionIsPresent(path, vcsRevision).len > 0

proc isVcsRevisionPresentOnBranch*(
    path: Path, vcsRevision: Sha1Hash, branchName: string): bool =
  ## Checks whether a given VCS revision `vcsRevision` is present on a branch
  ## with name `branchName` in a repository at path `path`. Returns `true` if
  ## so or `false` if either the branch don't exist or it does not contain the
  ## revision.
  ## 
  ## Raises a `NimbleError` if:
  ##   - the external source control tool is not found.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type

  let branches = getBranchesOnWhichVcsRevisionIsPresent(path, vcsRevision)
  return branches.contains(branchName)

proc retrieveRemoteChangeSets*(path: Path, remoteName, branchName: string) =
  ## Retrieve remote `remoteName` and branch `branchName` change sets for the
  ## repository at path `path`.
  ##
  ## Raises a `NimbleError` if:
  ##   - the external command fails.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type.

  discard tryDoVcsCmd(path,
    gitCmd = &"fetch {remoteName} {branchName}",
    hgCmd  = &"pull {remoteName} -b {branchName}")

proc retrieveRemoteChangeSets*(path: Path, remoteName: string) =
  ## Retrieve remote `remoteName` change sets for the repository at path `path`.
  ##
  ## Raises a `NimbleError` if:
  ##   - the external command fails.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type.

  discard tryDoVcsCmd(path,
    gitCmd = &"fetch {remoteName}",
    hgCmd  = &"pull {remoteName}")

proc retrieveRemoteChangeSets*(path: Path) =
  ## Retrieves all change sets for the repository at path `path` from every
  ## remote and every branch.
  ##
  ## Raises a `NimbleError` if:
  ##   - the external command fails.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type.

  for remote in getRemotesNames(path):
    retrieveRemoteChangeSets(path, remote)

proc setWorkingCopyToVcsRevision*(path: Path, vcsRevision: Sha1Hash) =
  ## Sets working copy of a repository at path `path` to have active a
  ## particular VCS revision `vcsRevision`.
  ## 
  ## Note: This is a detached state in the case of Git or a revision's branch
  ## in the case of Mercurial.
  ##
  ## Raises a `NimbleError` if:
  ##   - the external command fails.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type.

  discard tryDoVcsCmd(path,
    gitCmd = &"checkout {vcsRevision}",
    hgCmd  = &"update {vcsRevision}")

proc setCurrentBranchToVcsRevision*(path: Path, vcsRevision: Sha1Hash) =
  ## Changes the current VCS revision for repository at path `path`.
  ##
  ##   - For Git sets a current branch HEAD to point to the given VCS revision.
  ##
  ##   - For Mercurial just updates the working copy to the given VCS revision,
  ##     because in Mercurial the branch is part of the commit meta data.
  ## 
  ## Raises a `NimbleError` if:
  ##   - the external command fails.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type.

  discard tryDoVcsCmd(path,
    gitCmd = &"reset --hard {vcsRevision}",
    hgCmd  = &"update {vcsRevision}")

proc switchBranch*(path: Path, branchName: string) =
  ## Switches the current working copy at path `path` branch to `branchName`.
  ##
  ## Raises a `NimbleError` if:
  ##   - the external command fails.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type.

  discard tryDoVcsCmd(path,
    gitCmd = &"checkout {branchName}",
    hgCmd  = &"update {branchName}")

proc getCorrespondingRemoteAndBranch*(path: Path):
    tuple[remote, branch: string] =
  ## Gets the name of the remote and the remote branch which current branch of
  ## repository at path `path` tracks. If there is no such returns the default
  ## remote and current branch names.
  ## 
  ## Note: For Mercurial there is no such thing like remote tracing branch and
  ## this procedure always returns the default remote and current branch name.
  ##
  ## Raises a `NimbleError` if:
  ##   - the external source control tool is not found.
  ##   - the directory does not exist.
  ##   - the directory is not under supported VCS type

  var
    output: string
    exitCode: int

  let vcsType = path.getVcsType
  case vcsType
    of vcsTypeGit:
      (output, exitCode) = doCmdEx(git(path) & 
        " rev-parse --abbrev-ref --symbolic-full-name @{u}")
    of vcsTypeHg:
      (output, exitCode) = ("", QuitFailure)
    of vcsTypeNone:
      raise nimbleError(dirInNotUnderSourceControlErrorMsg(path))

  if exitCode == QuitSuccess:
    # Separate the remote name from the branch name.
    let remotes = path.getRemotesNames
    let output = output.strip
    for remote in remotes:
      if output.startsWith(remote):
        return (remote, output[remote.len + 1 .. ^1])
  else:
    return (vcsType.getVcsDefaultRemoteName, path.getCurrentBranch)

proc hasCorrespondingRemoteBranch*(path: Path, remoteBranches: HashSet[string]):
    tuple[hasBranch: bool, branchName: string] =
  # If the directory at path `path` is a Git repository and its current branch
  # has corresponding remote tracking branch in the provided set
  # `remoteBranches` returns `true` and the name of the branch or `false` and an
  # empty string otherwise.

  if path.getVcsType != vcsTypeGit:
    return (false, "")
  var (output, exitCode) = doCmdEx(git(path) &
    " rev-parse --abbrev-ref --symbolic-full-name @{u}")
  output = output.strip
  result.hasBranch = exitCode == QuitSuccess and output in remoteBranches
  if result.hasBranch:
    result.branchName = output

proc assertIsGitRepository(path: Path) =
  assert path.getVcsType == vcsTypeGit,
         "This procedure makes sense only for a Git repositories."

proc getLocalBranchesTrackingRemoteBranch*(path: Path, remoteBranch: string):
    seq[string] =
  ## By given path to a Git repository and a remote tracking branch name
  ## returns a sequence with all local branches which track the remote branch.
  path.assertIsGitRepository
  let output = tryDoCmdEx(git(path) &
    &" for-each-ref --format=\"%(if:equals={remoteBranch})%(upstream:short)%" &
     "(then)%(refname:short)%(end)\" refs/heads").strip
  if output.len > 0:
    output.split('\n')
  else:
    @[]

proc getLocalBranchName*(path: Path, remoteBranch: string): string =
  ## By given path to a Git repository and name of a remote branch returns a new
  ## name which to be used for a local branch name which consists of the name
  ## of the remote branch without a remote name prefix. For example:
  ##
  ##   * "origin/master" -> "master"
  ##   * "upstream/feature/lock-file" -> "feature/lock-file"

  path.assertIsGitRepository
  let remotes = path.getRemotesNames
  for remote in remotes:
    if remoteBranch.startsWith(remote):
      return remoteBranch[remote.len + 1 .. ^1]

proc fastForwardMerge*(path: Path, remoteBranch, localBranch: string) =
  ## Tries to fast forward merge a remote branch `remoteBranch` to a local
  ## branch `localBranch` in a Git repository at path `path`.
  path.assertIsGitRepository
  let currentBranch = path.getCurrentBranch
  tryDoCmdEx(&"{git(path)} checkout --detach")
  tryDoCmdEx(&"{git(path)} fetch . {remoteBranch}:{localBranch}")
  if currentBranch.len > 0:
    tryDoCmdEx(&"{git(path)} checkout {currentBranch}")

when isMainModule:
  import unittest, sequtils
  import ../../dist/checksums/src/checksums/sha1

  type
    NameToVcsRevision = OrderedTable[string, Sha1Hash]
      ## Maps some user supplied string id to VCS commit revision id.

  const
    tempDir = getTempDir()
    testGitDir = tempDir / "testGitDir"
    testHgDir = tempDir / "testHgDir"
    testNoVcsDir = tempDir / "testNoVcsDir"
    testSubDir = "testSubDir"
    testFile = "test.txt"
    testFile2 = "test2.txt"
    testFileContent = "This is a test file.\n"
    testSubDirFile = &"{testSubDir}/{testFile}"
    testRemotes: seq[tuple[name, url: string]] = @[
      ("origin", "testRemote1Dir"),
      ("other", "testRemote2Dir"),
      ("upstream", "testRemote3Dir")]
    noSuchVcsRevisionSha1 = initSha1Hash(
      "ffffffffffffffffffffffffffffffffffffffff")
    newBranchName = "new-branch"
    remoteNewBranch = &"{testRemotes[1].name}/{newBranchName}"
    newBranchFileName = "test2.txt"
    newBranchFileContent = "This is a new branch file content."
    testRemoteCommitFile = "remote.txt"

  var nameToVcsRevision: NameToVcsRevision

  proc getMercurialRcFileContent(): string =
    result = """
[ui]
username = John Doe <john.doe@example.com>
[paths]
"""
    for remote in testRemotes:
      result &= &"{remote.name} = {testHgDir / remote.url}\n"

  proc initRepo(vcsType: VcsType, url = ".") =
    tryDoCmdEx(&"{vcsType} init {url}")
    if vcsType == vcsTypeGit:
      tryDoCmdEx(&"git -C {url} config user.name \"John Doe\"")
      tryDoCmdEx(&"git -C {url} config user.email \"john.doe@example.com\"")

  proc collectFiles(files: varargs[string]): string =
    for file in files: result &= file & " "

  proc addFiles(vcsType: VcsType, files: varargs[string]) =
    tryDoCmdEx(&"{vcsType} add {collectFiles(files)}")

  proc revertAddFiles(vcsType: VcsType, files: varargs[string]) =
    let files = collectFiles(files)
    case vcsType
    of vcsTypeGit:
      tryDoCmdEx(&"git reset HEAD -- {files}")
    of vcsTypeHg:
      tryDoCmdEx(&"hg revert {files}")
    of vcsTypeNone:
      assert false, "Must not enter here."

  proc commit(vcsType: VcsType, name: string) =
    # Use user supplied name for the commit as commit message.
    tryDoCmdEx(&"{vcsType} commit -m {name}")
    nameToVcsRevision[name] = getVcsRevision(".")

  proc addRemotes(vcsType: VcsType) =
    case vcsType
    of vcsTypeGit:
      for remote in testRemotes:
        tryDoCmdEx(&"git remote add {remote.name} {remote.url}")
    of vcsTypeHg:
      writeFile(".hg/hgrc", getMercurialRcFileContent())
    of vcsTypeNone:
      assert false, "VCS type must not be 'vcsTypeNone'."

  proc setupRemoteRepo(vcsType: VcsType, remoteUrl: string) =
    createDir remoteUrl
    initRepo(vcsType, remoteUrl)
    if vcsType == vcsTypeGit:
      cd remoteUrl:
        tryDoCmdEx("git config receive.denyCurrentBranch ignore")

  proc setupRemoteRepos(vcsType: VcsType) =
    for remote in testRemotes:
      setupRemoteRepo(vcsType, remote.url)

  proc switchBranch(vcsType: VcsType, branchName: string) =
    let command = case vcsType
      of vcsTypeGit: "checkout"
      of vcsTypeHg:  "update"
      of vcsTypeNone:
        assert false, "Must not enter here."; ""

    tryDoCmdEx(&"{vcsType} {command} {branchName}")

  proc createCommitOnRemote(vcsType: VcsType, remoteName, remoteUrl: string) =
    cd remoteUrl:
      writeFile(testRemoteCommitFile, "")
      addFiles(vcsType, testRemoteCommitFile)
      commit(vcsType, remoteName)

  proc createCommitOnTestRemotes(vcsType: VcsType) =
    for remote in testRemotes:
      createCommitOnRemote(vcsType, remote.name, remote.url)

  proc setupNewBranch(vcsType: VcsType, branchName: string) =
    tryDoCmdEx(&"{vcsType} branch {branchName}")

  proc pushToRemote(vcsType: VcsType, remoteName: string) =
    if vcsType == vcsTypeGit and remoteName == gitDefaultRemote:
      let branchName = getCurrentBranch(".")
      tryDoCmdEx(&"git push --set-upstream {remoteName} {branchName}")
    tryDoCmdEx(&"{vcsType} push {remoteName}")

  proc pushToTestRemotes(vcsType: VcsType) =
    for remote in testRemotes:
      pushToRemote(vcsType, remote.name)

  proc createTestFiles() =
    writeFile(testFile, testFileContent)
    createDir testSubDir
    writeFile(testSubDirFile, "")

  proc commitInTheNewBranch(vcsType: VcsType, name: string) = 
    writeFile(newBranchFileName, newBranchFileContent)
    addFiles(vcsType, newBranchFileName)
    commit(vcsType, name)

  proc getExpectedLocalBranchesForVcsType(vcsType: VcsType): HashSet[string] =
    let defaultBranchName = vcsType.getVcsDefaultBranchName
    result = [defaultBranchName, newBranchName].toHashSet

  proc getExpectedRemoteTrackingBranchesForVcsType(vcsType: VcsType):
      HashSet[string] =
    if vcsType == vcsTypeGit:
      for remote in testRemotes:
        result.incl &"{remote.name}/{vcsType.getVcsDefaultBranchName}"
    else:
      result = vcsType.getExpectedLocalBranchesForVcsType

  proc getExpectedBranchesForVcsType(vcsType: VcsType): HashSet[string] =
    result = vcsType.getExpectedLocalBranchesForVcsType
    result = result + vcsType.getExpectedRemoteTrackingBranchesForVcsType

  proc createNewBranchOnTestRemotes(vcsType: VcsType) =
    for remote in testRemotes:
      cd remote.url:
        setupNewBranch(vcsType, newBranchName)

  proc setupSuite(vcsType: VcsType, vcsTestDir: string) =
    cdNewDir vcsTestDir:
      initRepo(vcsType)
      createTestFiles()
      addFiles(vcsType, testFile, testSubDirFile)
      commit(vcsType, vcsType.getVcsDefaultBranchName)
      addRemotes(vcsType)
      setupRemoteRepos(vcsType)
      pushToTestRemotes(vcsType)
      createCommitOnTestRemotes(vcsType)
      createNewBranchOnTestRemotes(vcsType)
      setupNewBranch(vcsType, newBranchName)
      if vcsType == vcsTypeHg:
        # Mercurial requires to have a commit for the new branch before
        # switching to it.
        commitInTheNewBranch(vcsType, newBranchName)
      switchBranch(vcsType, newBranchName)
      defer:
        # Restore the main branch on scope exit.
        switchBranch(vcsType, getVcsDefaultBranchName(vcsType))
      if vcsType != vcsTypeHg:
        # In the case of Mercurial at this point the commit is already done.
        commitInTheNewBranch(vcsType, newBranchName)

  template installRemoteTrackingBranch(testDir: string): untyped {.dirty.} =
    # A hack for `testDir` to be available in `&` macro.
    let td = testDir
    # Fetch remote branch
    tryDoCmdEx(&"git -C {td} fetch {testRemotes[1].name} {newBranchName}")
    defer:
      # Delete the newly fetched remote branch on scope exit to clean the
      # state of the repo.
      tryDoCmdEx(
        &"git -C {td} branch -dr {testRemotes[1].name}/{newBranchName}")

    # Tell the current branch to track it
    tryDoCmdEx(
      &"git -C {td} branch -u {testRemotes[1].name}/{newBranchName}")

  proc setupNoVcsSuite() =
    cdNewDir testNoVcsDir:
      createTestFiles()

  proc tearDownSuite(dir: string) =
    removeDir dir

  template suiteTestCode(vcsType: VcsType, testDir: string,
                         remoteUrlPath: untyped) {.dirty.} =
    assert vcsType != vcsTypeNone,
           "The type of the VCS must not be 'vcsTypeNone'"

    setupSuite(vcsType, testDir)

    test "getVcsTypeAndSpecialDirPath":
      let expectedVcsSpecialDirPath = testDir.Path / getVcsSpecialDir(vcsType)
      check getVcsTypeAndSpecialDirPath(testDir) ==
            (vcsType, expectedVcsSpecialDirPath)
      check getVcsTypeAndSpecialDirPath(testDir / testSubDir) ==
            (vcsType, expectedVcsSpecialDirPath)

    test "getVcsRevision":
      check isValidSha1Hash($getVcsRevision(testDir))

    test "getPackageFileList":
      check getPackageFileList(testDir) == @[testFile, testSubDirFile]

    test "isWorkingCopyClean":
      check isWorkingCopyClean(testDir)
      cd testDir:
        # Make working copy state not clean.
        writeFile(testFile2, "")
        addFiles(vcsType, testFile2)
      defer:
        # Restore previous state on scope exit.
        cd testDir:
          revertAddFiles(vcsType, testFile2)
          removeFile testFile2
      check not isWorkingCopyClean(testDir)

    test "getRemotesNames":
      check getRemotesNames(testDir) == testRemotes.mapIt(it.name)
      for remote in testRemotes:
        # Test for empty list when there are not set remotes.
        check getRemotesNames(testDir/remote.url) == newSeq[string]()

    test "getRemotePushUrl":
      for remote in testRemotes:
        check getRemotePushUrl(testDir, remote.name) == remoteUrlPath

    test "getRemotesPushUrls":
      var remoteUrls: seq[string]
      for remote in testRemotes:
        # Test for empty list when there are not set remotes.
        check getRemotesPushUrls(testDir/remote.url) == newSeq[string]()
        remoteUrls.add remoteUrlPath
      check getRemotesPushUrls(testDir) == remoteUrls

    test "isVcsRevisionPresentOnSomeRemote":
      let vcsRevision = getVcsRevision(testDir)
      check isVcsRevisionPresentOnSomeRemote(testDir, vcsRevision)
      check not isVcsRevisionPresentOnSomeRemote(testDir, noSuchVcsRevisionSha1)

    test "getCurrentBranch":
      let vcsDefaultBranchName = getVcsDefaultBranchName(vcsType)
      check getCurrentBranch(testDir) == vcsDefaultBranchName
      cd testDir:
        switchBranch(vcsType, newBranchName)
        defer: switchBranch(vcsType, vcsDefaultBranchName)
        check getCurrentBranch(".") == newBranchName
      check getCurrentBranch(testDir) == vcsDefaultBranchName

    test "getBranchesOnWhichVcsRevisionIsPresent":
      let vcsRevision = getVcsRevision(testDir)

      check getBranchesOnWhichVcsRevisionIsPresent(
              testDir, vcsRevision, btBoth) ==
            vcsType.getExpectedBranchesForVcsType

      check getBranchesOnWhichVcsRevisionIsPresent(
              testDir, vcsRevision, btLocal) ==
            vcsType.getExpectedLocalBranchesForVcsType

      check getBranchesOnWhichVcsRevisionIsPresent(
              testDir, vcsRevision, btRemoteTracking) ==
            vcsType.getExpectedRemoteTrackingBranchesForVcsType

      check getBranchesOnWhichVcsRevisionIsPresent(
        testDir, noSuchVcsRevisionSha1) == HashSet[string]()

    test "isVcsRevisionPresentOnSomeBranch":
      check isVcsRevisionPresentOnSomeBranch(
        testDir, getVcsRevision(testDir))
      check not isVcsRevisionPresentOnSomeBranch(
        testDir, noSuchVcsRevisionSha1)

    test "isVcsRevisionPresentOnBranch":
      let vcsRevision = getVcsRevision(testDir)
      let branchName = getCurrentBranch(testDir)
      check isVcsRevisionPresentOnBranch(testDir, vcsRevision, branchName)
      check not isVcsRevisionPresentOnBranch(
        testDir, noSuchVcsRevisionSha1, branchName)
      check not isVcsRevisionPresentOnBranch(
        testDir, vcsRevision, "not-existing-branch")

    test "retrieveRemoteChangeSets (for single remote and branch)":
      let remoteName = testRemotes[2].name
      let remoteVcsRevision = nameToVcsRevision[remoteName]
      check not isVcsRevisionPresentOnSomeBranch(testDir, remoteVcsRevision)
      retrieveRemoteChangeSets(testDir, remoteName,
                               vcsType.getVcsDefaultBranchName)
      check isVcsRevisionPresentOnSomeBranch(testDir, remoteVcsRevision)

    test "retrieveRemoteChangeSets (for single remote)":
      let remoteName = testRemotes[0].name
      let remoteVcsRevision = nameToVcsRevision[remoteName]
      check not isVcsRevisionPresentOnSomeBranch(testDir, remoteVcsRevision)
      retrieveRemoteChangeSets(testDir, remoteName)
      check isVcsRevisionPresentOnSomeBranch(testDir, remoteVcsRevision)

    test "retrieveRemoteChangeSets (for all remotes and branches)":
      let remoteVcsRevision = nameToVcsRevision[testRemotes[1].name]
      check not isVcsRevisionPresentOnSomeBranch(testDir, remoteVcsRevision)
      retrieveRemoteChangeSets(testDir)
      check isVcsRevisionPresentOnSomeBranch(testDir, remoteVcsRevision)

    test "setWorkingCopyToVcsRevision":
      let oldRevision = getVcsRevision(testDir)
      let changeRevision = nameToVcsRevision[newBranchName]
      setWorkingCopyToVcsRevision(testDir, changeRevision)
      defer:
        # Restore the repository state at scope exit.
        cd testDir: switchBranch(vcsType, getVcsDefaultBranchName(vcsType))
      let newRevision = getVcsRevision(testDir)
      check newRevision != oldRevision
      check newRevision == changeRevision

    test "setCurrentBranchToVcsRevision":
      let oldRevision = getVcsRevision(testDir)
      let changeRevision = nameToVcsRevision[newBranchName]
      let branchName = getCurrentBranch(testDir)
      setCurrentBranchToVcsRevision(testDir, changeRevision)
      defer:
        # Restore the repository state at scope exit.
        setCurrentBranchToVcsRevision(testDir, oldRevision)
        check getVcsRevision(testDir) == oldRevision
      let newRevision = getVcsRevision(testDir)
      # Check that the revision is actually changed,
      check newRevision != oldRevision
      # to the intended one.
      check newRevision == changeRevision
      case vcsType
        of vcsTypeGit:
          # In the case of Git test that the branch is not changed,
          check getCurrentBranch(testDir) == branchName
        of vcsTypeHg:
          # but for Mercurial the branch name is part of the commit meta data
          # and it will be changed.
          check getCurrentBranch(testDir) == newBranchName
        of vcsTypeNone:
          assert false, "Must not enter here."

    test "switchBranch":
      switchBranch(testDir, newBranchName)
      defer:
        # Restore the repository state at scope exit.
        cd testDir: switchBranch(vcsType, getVcsDefaultBranchName(vcsType))
      check getCurrentBranch(testDir) == newBranchName
      expect NimbleError: switchBranch(testDir, "not-existing-branch")

    test "getCorrespondingRemoteAndBranch":
      let (remote, branch) = testDir.getCorrespondingRemoteAndBranch
      # There is no setup remote tracking branch and the default remote name for
      # the VCS type and current branch name are returned.
      check remote == vcsType.getVcsDefaultRemoteName
      check branch == testDir.getCurrentBranch

      if vcsType == vcsTypeGit:
        testDir.installRemoteTrackingBranch
        let (remote, branch) = testDir.getCorrespondingRemoteAndBranch
        check remote == testRemotes[1].name
        check branch == newBranchName

    test "hasCorrespondingRemoteBranch":
      if vcsType == vcsTypeGit:
        testDir.installRemoteTrackingBranch
        let remoteTrackingBranches = getBranchesOnWhichVcsRevisionIsPresent(
          testDir, testDir.getVcsRevision, btRemoteTracking)
        check testDir.hasCorrespondingRemoteBranch(remoteTrackingBranches) ==
              (true, remoteNewBranch)
      else:
        check testDir.hasCorrespondingRemoteBranch(HashSet[string]()) ==
              (false, "")

    test "getLocalBranchesTrackingRemoteBranch":
      if vcsType == vcsTypeGit:
        testDir.installRemoteTrackingBranch
        check testDir.getLocalBranchesTrackingRemoteBranch("not-existing") ==
              newSeqOfCap[string](0)
        check testDir.getLocalBranchesTrackingRemoteBranch(remoteNewBranch) ==
              @[vcsType.getVcsDefaultBranchName]
      else:
        skip()

    test "getLocalBranchName":
      if vcsType == vcsTypeGit:
        check testDir.getLocalBranchName(remoteNewBranch) == newBranchName
      else:
        skip()

    test "fastForwardMerge":
      if vcsType == vcsTypeGit:
        const testBranchName = "test-branch"
        cd testDir:
          vcsType.setupNewBranch(testBranchName)
          vcsType.switchBranch(testBranchName)
        testDir.installRemoteTrackingBranch
        cd testDir: vcsType.switchBranch(vcsType.getVcsDefaultBranchName)
        testDir.fastForwardMerge(remoteNewBranch, testBranchName)
        expect NimbleError:
          testDir.fastForwardMerge(remoteNewBranch, newBranchName)
      else:
        skip()

    tearDownSuite(testDir)

  suite "Git":
    suiteTestCode(vcsTypeGit, testGitDir): remote.url

  suite "Mercurial":
    suiteTestCode(vcsTypeHg, testHgDir):
      testHgDir / remote.url

  suite "no version control":
    setupNoVcsSuite()

    test "getVcsTypeAndSpecialDirPath":
      const rootDir = when defined(windows): ':' else: '/'
      let (vcsType, specialDirPath) = getVcsTypeAndSpecialDirPath(testNoVcsDir)
      check vcsType == vcsTypeNone
      check ($specialDirPath)[^1] == rootDir

    test "getVcsRevision":
      check not isValidSha1Hash($getVcsRevision(testNoVcsDir))

    test "getPackageFileList":
      check getPackageFileList(testNoVcsDir) == @[testFile, testSubDirFile]

    tearDownSuite(testNoVcsDir)
