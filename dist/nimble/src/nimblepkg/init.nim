import os, strutils

import ./cli, ./tools

type
  PkgInitInfo* = tuple
    pkgName: string
    pkgVersion: string
    pkgAuthor: string
    pkgDesc: string
    pkgLicense: string
    pkgSrcDir: string
    pkgNimDep: string
    pkgType: string

proc writeExampleIfNonExistent(file: string, content: string) =
  if not fileExists(file):
    writeFile(file, content)
  else:
    display("Info:", "File " & file & " already exists, did not write " &
            "example code", priority = HighPriority)

proc createPkgStructure*(info: PkgInitInfo, pkgRoot: string) =
  # Create source directory
  createDirD(pkgRoot / info.pkgSrcDir)

  # Initialise the source code directories and create some example code.
  var nimbleFileOptions = ""
  case info.pkgType
  of "binary":
    let mainFile = pkgRoot / info.pkgSrcDir / info.pkgName.changeFileExt("nim")
    writeExampleIfNonExistent(mainFile,
"""
# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.

when isMainModule:
  echo("Hello, World!")
"""
    )
    nimbleFileOptions.add("bin           = @[\"$1\"]\n" % info.pkgName)
  of "library":
    let mainFile = pkgRoot / info.pkgSrcDir / info.pkgName.changeFileExt("nim")
    writeExampleIfNonExistent(mainFile,
"""
# This is just an example to get you started. A typical library package
# exports the main API in this file. Note that you cannot rename this file
# but you can remove it if you wish.

proc add*(x, y: int): int =
  ## Adds two numbers together.
  return x + y
"""
    )

    createDirD(pkgRoot / info.pkgSrcDir / info.pkgName)
    let submodule = pkgRoot / info.pkgSrcDir / info.pkgName /
        "submodule".addFileExt("nim")
    writeExampleIfNonExistent(submodule,
"""
# This is just an example to get you started. Users of your library will
# import this file by writing ``import $1/submodule``. Feel free to rename or
# remove this file altogether. You may create additional modules alongside
# this file as required.

type
  Submodule* = object
    name*: string

proc initSubmodule*(): Submodule =
  ## Initialises a new ``Submodule`` object.
  Submodule(name: "Anonymous")
""" % info.pkgName
    )
  of "hybrid":
    let mainFile = pkgRoot / info.pkgSrcDir / info.pkgName.changeFileExt("nim")
    writeExampleIfNonExistent(mainFile,
"""
# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import $1pkg/submodule

when isMainModule:
  echo(getWelcomeMessage())
""" % info.pkgName
    )

    let pkgSubDir = pkgRoot / info.pkgSrcDir / info.pkgName & "pkg"
    createDirD(pkgSubDir)
    let submodule = pkgSubDir / "submodule".addFileExt("nim")
    writeExampleIfNonExistent(submodule,
"""
# This is just an example to get you started. Users of your hybrid library will
# import this file by writing ``import $1pkg/submodule``. Feel free to rename or
# remove this file altogether. You may create additional modules alongside
# this file as required.

proc getWelcomeMessage*(): string = "Hello, World!"
""" % info.pkgName
    )
    nimbleFileOptions.add("installExt    = @[\"nim\"]\n")
    nimbleFileOptions.add("bin           = @[\"$1\"]\n" % info.pkgName)
  else:
    assert false, "Invalid package type specified."

  let pkgTestDir = "tests"
  # Create test directory
  case info.pkgType
  of "binary":
    discard
  of "hybrid", "library":
    let pkgTestPath = pkgRoot / pkgTestDir
    createDirD(pkgTestPath)

    writeFile(pkgTestPath / "config".addFileExt("nims"),
      "switch(\"path\", \"$$projectDir/../$#\")" % info.pkgSrcDir
    )

    if info.pkgType == "library":
      writeExampleIfNonExistent(pkgTestPath / "test1".addFileExt("nim"),
"""
# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import $1
test "can add":
  check add(5, 5) == 10
""" % info.pkgName
      )
    else:
      writeExampleIfNonExistent(pkgTestPath / "test1".addFileExt("nim"),
"""
# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import $1pkg/submodule
test "correct welcome":
  check getWelcomeMessage() == "Hello, World!"
""" % info.pkgName
      )
  else:
    assert false, "Invalid package type specified."

  # Write the nimble file
  let nimbleFile = pkgRoot / info.pkgName.changeFileExt("nimble")
  writeFile(nimbleFile, """# Package

version       = $#
author        = "$#"
description   = "$#"
license       = $#
srcDir        = $#
$#

# Dependencies

requires "nim >= $#"
""" % [
      info.pkgVersion.escape(), info.pkgAuthor.replace("\"", "\\\""), info.pkgDesc.replace("\"", "\\\""),
      info.pkgLicense.escape(), info.pkgSrcDir.escape(), nimbleFileOptions,
      info.pkgNimDep
    ]
  )

  display("Info:", "Nimble file created successfully", priority=MediumPriority)
