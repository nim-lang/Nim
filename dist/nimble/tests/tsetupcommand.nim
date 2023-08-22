# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

{.used.}

import unittest, os, strutils, osproc
import testscommon
from nimble import nimblePathsFileName, nimbleConfigFileName
from nimblepkg/common import cd
from nimblepkg/developfile import developFileName

suite "setup command":
  cleanDir installDir
  test "nimble setup (without develop file)":
    cd "setup/binary":
      usePackageListFile "../../develop/packages.json":
        cleanFiles nimblePathsFileName, nimbleConfigFileName, "binary"
        let (_, exitCode) = execNimble("setup")
        check exitCode == QuitSuccess
        # Check that the paths and config files are generated.
        check fileExists(nimblePathsFileName)
        check fileExists(nimbleConfigFileName)
        # Check that the paths file contains the right path/
        let pkgADir = getPackageDir(pkgsDir, "packagea-0.2.0")
        let pkgBDir = getPackageDir(pkgsDir, "packageb-0.1.0")
        let pathsFileContent = nimblePathsFileName.readFile
        check pathsFileContent.contains(pkgADir)
        check pathsFileContent.contains(pkgBDir)
        # Check that Nim can use "nimble.paths" file to find dependencies and
        # build the project.
        let (_, nimExitCode) = execCmdEx("nim c -r binary")
        check nimExitCode == QuitSuccess

  test "nimble setup (with develop file)":
    cd "setup/dependent":
      usePackageListFile "../../develop/packages.json":
        cleanFiles nimblePathsFileName, nimbleConfigFileName,
                   developFileName, "dependent"
        let (_, developExitCode) = execNimble("develop", "-a:../dependency")
        check developExitCode == QuitSuccess
        let (_, setupExitCode) = execNimble("setup")
        check setupExitCode == QuitSuccess
        # Check that the paths and config files are generated.
        check fileExists(nimblePathsFileName)
        check fileExists(nimbleConfigFileName)
        # Check that develop mode dependency path is written in the
        # "nimble.paths" file.
        let developDepDir =
          (getCurrentDir() / ".." / "dependency").normalizedPath
        check nimblePathsFileName.readFile.contains(developDepDir.escape)
        # Check that Nim can use "nimble.paths" file to find dependencies and
        # build the project.
        let (_, nimExitCode) = execCmdEx("nim c -r dependent")
        check nimExitCode == QuitSuccess

  test "Check if upgrading of setup section":
    cd "setupproject":
      cleanFiles nimblePathsFileName, nimbleConfigFileName, "nimble.lock", ".gitignore"
      discard execNimble("setup")
      var configFileContent = nimbleConfigFileName.readFile
      check not configFileContent.contains("--noNimblePath")
      let (_, developExitCode) = execNimble("lock")
      check developExitCode == QuitSuccess

      # update of the section works
      discard execNimble("setup")
      check fileExists("nimble.lock")
      configFileContent = nimbleConfigFileName.readFile
      check configFileContent.contains("--noNimblePath")

      cleanFiles nimblePathsFileName, nimbleConfigFileName, "nimble.lock", ".gitignore"
