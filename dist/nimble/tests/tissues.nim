# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

{.used.}

import unittest, os, osproc, strutils, sequtils, strformat
import testscommon
from nimblepkg/common import cd, nimbleVersion, nimblePackagesDirName
from nimblepkg/version import newVersion
from nimblepkg/displaymessages import cannotUninstallPkgMsg

suite "issues":
  test "test params":
    cd "testParams":
      let (output, exitCode) = execNimbleYes("test", "Passing test")

      check exitCode == QuitSuccess
      check output.contains("Passing test")

  test "issue 801":
    cd "issue801":
      let (output, exitCode) = execNimbleYes("test")
      check exitCode == QuitSuccess

      # Verify hooks work
      check output.contains("before test")
      check output.contains("after test")

  test "issue 799":
    # When building, any newly installed packages should be referenced via the
    # path that they get permanently installed at.
    cleanDir installDir
    cd "issue799":
      let (output, exitCode) = execNimbleYes("build")
      check exitCode == QuitSuccess
      var lines = output.processOutput
      lines.keepItIf(unindent(it).startsWith("Executing"))

      for line in lines:
        if line.contains("issue799"):
          let nimbleInstallDir = getPackageDir(
            pkgsDir, &"nimble-{nimbleVersion}")
          let pkgInstalledPath = "--path:'" & nimble_install_dir & "'"
          check line.contains(pkgInstalledPath)

  test "issue 793":
    cd "issue793":
      var (output, exitCode) = execNimble("build")
      check exitCode == QuitSuccess
      check output.contains("before build")
      check output.contains("after build")

      # Issue 776
      (output, exitCode) = execNimble("doc", "src/issue793")
      check output.contains("before doc")
      check output.contains("after doc")

  test "issue 727":
    cd "issue727":
      var (output, exitCode) = execNimbleYes("c", "src/abc")
      check exitCode == QuitSuccess
      check fileExists(buildTests / "abc".addFileExt(ExeExt))
      check not fileExists("src/def".addFileExt(ExeExt))
      check not fileExists(buildTests / "def".addFileExt(ExeExt))

      (output, exitCode) = execNimbleYes("uninstall", "-i", "timezones")
      check exitCode == QuitSuccess

      (output, exitCode) = execNimbleYes("run", "def")
      check exitCode == QuitSuccess
      check output.contains("def727")
      check not fileExists("abc".addFileExt(ExeExt))
      check fileExists("def".addFileExt(ExeExt))

      (output, exitCode) = execNimbleYes("uninstall", "-i", "timezones")
      check exitCode == QuitSuccess

  test "issue 708":
    cd "issue708":
      # TODO: We need a way to filter out compiler messages from the messages
      # written by our nimble scripts.
      let (output, exitCode) = execNimbleYes("install", "--verbose")
      check exitCode == QuitSuccess
      let lines = output.strip.processOutput()
      check(inLines(lines, "hello"))
      check(inLines(lines, "hello2"))

  test "do not install single dependency multiple times (#678)":
    # for the test to be correct, the tested package and its dependencies must not
    # exist in the local cache
    removeDir("nimbleDir")
    cd "issue678":
      testRefresh():
        writeFile(configFile, """
          [PackageList]
          name = "local"
          path = "$1"
        """.unindent % (getCurrentDir() / "packages.json").replace("\\", "\\\\"))
        check execNimble(["refresh"]).exitCode == QuitSuccess
        let (output, exitCode) = execNimbleYes("install")
        check exitCode == QuitSuccess
        let index = output.find("issue678_dependency_1@0.1.0 already exists")
        check index == stringNotFound

  test "Passing command line arguments to a task (#633)":
    cd "issue633":
      let (output, exitCode) = execNimble("testTask", "--testTask")
      check exitCode == QuitSuccess
      check output.contains("Got it")

  test "error if `bin` is a source file (#597)":
    cd "issue597":
      let (output, exitCode) = execNimble("build")
      check exitCode != QuitSuccess
      check output.contains("entry should not be a source file: test.nim")

  test "init does not overwrite existing files (#581)":
    createDir("issue581/src")
    cd "issue581":
      const Src = "echo \"OK\""
      writeFile("src/issue581.nim", Src)
      check execNimbleYes("init").exitCode == QuitSuccess
      check readFile("src/issue581.nim") == Src
    removeDir("issue581")

  test "issue 564":
    cd "issue564":
      let (_, exitCode) = execNimble("build")
      check exitCode == QuitSuccess

  test "issues #280 and #524":
    check execNimbleYes("install",
      "https://github.com/nimble-test/issue280and524.git").exitCode == 0

  test "issues #308 and #515":
    let
      ext = when defined(Windows): ExeExt else: "out"
    cd "issue308515" / "v1":
      var (output, exitCode) = execNimble(["run", "binname", "--silent"])
      check exitCode == QuitSuccess
      check output.contains "binname"

      (output, exitCode) = execNimble(["run", "binname-2", "--silent"])
      check exitCode == QuitSuccess
      check output.contains "binname-2"

      # Install v1 and check
      (output, exitCode) = execNimbleYes(["install", "--verbose"])
      check exitCode == QuitSuccess
      check output.contains getPackageDir(pkgsDir, "binname-0.1.0") /
                            "binname".addFileExt(ext)
      check output.contains getPackageDir(pkgsDir, "binname-0.1.0") /
                            "binname-2"

      (output, exitCode) = execBin("binname")
      check exitCode == QuitSuccess
      check output.contains "binname 0.1.0"
      (output, exitCode) = execBin("binname-2")
      check exitCode == QuitSuccess
      check output.contains "binname-2 0.1.0"

    cd "issue308515" / "v2":
      # Install v2 and check
      var (output, exitCode) = execNimbleYes(["install", "--verbose"])
      check exitCode == QuitSuccess
      check output.contains getPackageDir(pkgsDir, "binname-0.2.0") /
                            "binname".addFileExt(ext)
      check output.contains getPackageDir(pkgsDir, "binname-0.2.0") /
                            "binname-2"

      (output, exitCode) = execBin("binname")
      check exitCode == QuitSuccess
      check output.contains "binname 0.2.0"
      (output, exitCode) = execBin("binname-2")
      check exitCode == QuitSuccess
      check output.contains "binname-2 0.2.0"

      # Uninstall and check v1 back
      (output, exitCode) = execNimbleYes("uninstall", "binname@0.2.0")
      check exitCode == QuitSuccess

      (output, exitCode) = execBin("binname")
      check exitCode == QuitSuccess
      check output.contains "binname 0.1.0"
      (output, exitCode) = execBin("binname-2")
      check exitCode == QuitSuccess
      check output.contains "binname-2 0.1.0"

  test "issue 432":
    cd "issue432":
      check execNimbleYes("install", "--depsOnly").exitCode == QuitSuccess
      check execNimbleYes("install", "--depsOnly").exitCode == QuitSuccess

  test "issue #428":
    cd "issue428":
      # Note: Can't use execNimble because it patches nimbleDir
      const localNimbleDir = "./nimbleDir"
      cleanDir localNimbleDir
      let (_, exitCode) = execCmdEx(
        &"{nimblePath} -y --nimbleDir={localNimbleDir} install")
      check exitCode == QuitSuccess
      let dummyPkgDir = getPackageDir(
        localNimbleDir / nimblePackagesDirName, "dummy-0.1.0")
      check dummyPkgDir.dirExists
      check not (dummyPkgDir / "nimbleDir").dirExists

  test "issue 399":
    cd "issue399":
      var (output, exitCode) = execNimbleYes("install")
      check exitCode == QuitSuccess

      (output, exitCode) = execBin("subbin")
      check exitCode == QuitSuccess
      check output.contains("subbin-1")

  test "can pass args with spaces to Nim (#351)":
    cd "binaryPackage/v2":
      let (output, exitCode) = execCmdEx(nimblePath &
                                        " c -r" &
                                        " -d:myVar=\"string with spaces\"" &
                                        " binaryPackage")
      checkpoint output
      check exitCode == QuitSuccess

  test "issue #349":
    let reservedNames = [
      "CON",
      "PRN",
      "AUX",
      "NUL",
      "COM1",
      "COM2",
      "COM3",
      "COM4",
      "COM5",
      "COM6",
      "COM7",
      "COM8",
      "COM9",
      "LPT1",
      "LPT2",
      "LPT3",
      "LPT4",
      "LPT5",
      "LPT6",
      "LPT7",
      "LPT8",
      "LPT9",
    ]

    proc checkName(name: string) =
      let (outp, code) = execNimbleYes("init", name)
      let msg = outp.strip.processOutput()
      check code == QuitFailure
      check inLines(msg,
        "\"$1\" is an invalid package name: reserved name" % name)
      try:
        removeFile(name.changeFileExt("nimble"))
        removeDir("src")
        removeDir("tests")
      except OSError:
        discard

    for reserved in reservedNames:
      checkName(reserved.toUpperAscii())
      checkName(reserved.toLowerAscii())

  test "issue #338":
    cd "issue338":
      check execNimbleYes("install").exitCode == QuitSuccess

  test "can distinguish package reading in nimbleDir vs. other dirs (#304)":
    cd "issue304" / "package-test":
      check execNimble("tasks").exitCode == QuitSuccess

  test "can build with #head and versioned package (#289)":
    cleanDir(installDir)
    cd "issue289":
      check execNimbleYes("install").exitCode == QuitSuccess

    check execNimbleYes(["uninstall", "issue289"]).exitCode == QuitSuccess
    check execNimbleYes(["uninstall", "packagea"]).exitCode == QuitSuccess

  test "issue #206":
    cd "issue206":
      var (output, exitCode) = execNimbleYes("install")
      check exitCode == QuitSuccess
      (output, exitCode) = execNimbleYes("install")
      check exitCode == QuitSuccess

  test "can install diamond deps (#184)":
    cd "diamond_deps":
      cd "d":
        check execNimbleYes("install").exitCode == 0
      cd "c":
        check execNimbleYes("install").exitCode == 0
      cd "b":
        check execNimbleYes("install").exitCode == 0
      cd "a":
        # TODO: This doesn't really test anything. But I couldn't quite
        # reproduce #184.
        let (output, exitCode) = execNimbleYes("install")
        checkpoint(output)
        check exitCode == 0

  test "can validate package structure (#144)":
    # Test that no warnings are produced for correctly structured packages.
    for package in ["a", "b", "c", "validBinary", "softened"]:
      cd "packageStructure/" & package:
        let (output, exitCode) = execNimbleYes("install")
        check exitCode == QuitSuccess
        let lines = output.strip.processOutput()
        check(not lines.hasLineStartingWith("Warning:"))

    # Test that warnings are produced for the incorrectly structured packages.
    for package in ["x", "y", "z"]:
      cd "packageStructure/" & package:
        let (output, exitCode) = execNimbleYes("install")
        check exitCode == QuitSuccess
        let lines = output.strip.processOutput()
        checkpoint(output)
        case package
        of "x":
          check lines.hasLineStartingWith(
            "Warning: Package 'x' has an incorrect structure. It should" &
            " contain a single directory hierarchy for source files," &
            " named 'x', but file 'foobar.nim' is in a directory named" &
            " 'incorrect' instead.")
        of "y":
          check lines.hasLineStartingWith(
            "Warning: Package 'y' has an incorrect structure. It should" &
            " contain a single directory hierarchy for source files," &
            " named 'ypkg', but file 'foobar.nim' is in a directory named" &
            " 'yWrong' instead.")
        of "z":
          check lines.hasLineStartingWith(
            "Warning: Package 'z' has an incorrect structure. The top level" &
            " of the package source directory should contain at most one module," &
            " named 'z.nim', but a file named 'incorrect.nim' was found.")
        else:
          assert false

  test "issue 129 (installing commit hash)":
    cleanDir(installDir)
    let arguments = @["install", &"{pkgAUrl}@#1f9cb289c89"]
    check execNimbleYes(arguments).exitCode == QuitSuccess
    # Verify that it was installed correctly.
    check packageDirExists(pkgsDir, "PackageA-0.6.0")
    # Remove it so that it doesn't interfere with the uninstall tests.
    check execNimbleYes("uninstall", "packagea@#1f9cb289c89").exitCode ==
          QuitSuccess

  test "issue #126":
    cd "issue126/a":
      let (output, exitCode) = execNimbleYes("install")
      let lines = output.strip.processOutput()
      check exitCode != QuitSuccess # TODO
      check inLines(lines, "issue-126 is an invalid package name: cannot contain '-'")

    cd "issue126/b":
      let (output1, exitCode1) = execNimbleYes("install")
      let lines1 = output1.strip.processOutput()
      check exitCode1 != QuitSuccess
      check inLines(lines1, "The .nimble file name must match name specified inside")

  test "issue 113 (uninstallation problems)":
    cleanDir(installDir)

    cd "issue113/c":
      check execNimbleYes("install").exitCode == QuitSuccess
    cd "issue113/b":
      check execNimbleYes("install").exitCode == QuitSuccess
    cd "issue113/a":
      check execNimbleYes("install").exitCode == QuitSuccess

    # Try to remove c.
    let
      (output, exitCode) = execNimbleYes(["remove", "c"])
      lines = output.strip.processOutput()
      pkgBInstallDir = getPackageDir(pkgsDir, "b-0.1.0").splitPath.tail

    check exitCode != QuitSuccess
    check lines.inLines(
      cannotUninstallPkgMsg("c", newVersion("0.1.0"), @[pkgBInstallDir]))

    check execNimbleYes(["remove", "a"]).exitCode == QuitSuccess
    check execNimbleYes(["remove", "b"]).exitCode == QuitSuccess

    cd "issue113/buildfail":
      check execNimbleYes("install").exitCode != QuitSuccess

    check execNimbleYes(["remove", "c"]).exitCode == QuitSuccess

  test "issue #108":
    cd "issue108":
      let (output, exitCode) = execNimble("build")
      let lines = output.strip.processOutput()
      check exitCode != QuitSuccess
      check inLines(lines, "Nothing to build")

  test "issue #941 (add binaries' extensions in nimble dump command)":
    cd "issue941":
      let (output, exitCode) = execNimble("dump")
      check exitCode == QuitSuccess
      const expectedBinaryName =
        when defined(windows):
          "issue941.dll"
        else:
          "libissue941.so"
      check output.contains(expectedBinaryName)

  test "issue #953 (Use refreshed package list)":
    # Remove all packages from the json file so it needs to be refreshed
    writeFile(installDir / "packages_official.json", "[]")
    removeDir(installDir / "pkgs2")

    let (output, exitCode) = execNimble("install", "-y", "fusion")
    let lines = output.strip.processOutput()
    # Test that it needed to refresh packages and that it installed
    check:
      exitCode == QuitSuccess
      inLines(lines, "check internet for updated packages")
      inLines(lines, "fusion installed successfully")

    # Clean up package file
    check execNimble(["refresh"]).exitCode == QuitSuccess
